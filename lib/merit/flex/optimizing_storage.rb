# frozen_string_literal: true

module Merit
  module Flex
    # Optimizing storage receives a residual load curve (demand minus supply) and uses storage in an
    # attempt to flatten this curve as much as possible. It does this by charging during hours where
    # the curve is relatively low, and discharging when high.
    #
    # The algorithm respects the input capacity, output capacity, and volume of the battery, and
    # optionally supports an output efficiency for modelling round-trip losses.
    module OptimizingStorage
      # Contains behavior for the production half of the optimizing storage.
      class Producer < Merit::CurveProducer
      end

      # Contains behavior for the consumption half of the optimizing storage.
      class Consumer < Merit::User::WithCurve
        public_class_method :new
      end

      # Stores each hour and its current value.
      Frame = Struct.new(:index, :value)

      # Runs the optimization calculating how much will be stored in each hour.
      #
      # The algorithm works like so:
      #
      # 1. Order all hours from lowest value (load) to highest.
      # 2. Pop the highest hour.
      # 3. Search in earlier hours (as far as `lookbehind` specifies) for the hour where the value
      #    is lowest. An hour is only selected if its value is 95% or lower than the highest hour
      #    value. This reduces the number of iterations by avoiding many small charges/discharges.
      # 4. Place a charge in the low hour (min) and a discharge in the high hour (max).
      #
      # The charge/discharge in step 4 has several constraints:
      #
      # * The available battery volume between the min and max hours.
      # * The remaining input capacity in the min hour and output capacity in the max hour.
      # * One quarter of the difference in value between the min and max hour.
      #
      # Rather than equalizing the load of the two hours (`(max - min) / 2`), we assign at most one
      # quarter of the difference as this allows energy to be "spread" more fairly across many
      # hours. Not doing this tends to reduce the absolute peak hours while leaving the surrounding
      # hours unaffected. Changing this constant (for example, to one tenth of the difference) can
      # produce smoother, flatter curves at the expensive of increased run-time. One quarter was
      # found to be a good compromise for real-world curves.
      #
      # Arguments:
      # data               - The residual load curve
      # charging_target    - Curve describing the desired charging in each hour
      # discharging_target - Curve describing the desired discharging in each hour
      #
      # Keyword arguments:
      # volume            - The volume of the battery in MWh.
      # input_capacity    - The input capacity of the battery in MW.
      # output_capacity   - The output capacity of the battery in MW.
      # lookbehind        - How many hours the algorithm can look into the past to search for the
      #                     minimum.
      # charging_limit    - An optional curve which describes how much the battery may charge in
      #                     each hour. This will be further limited by the input capacity.
      # discharging_limit - An optional curve which describes how much the battery may discharge in
      #                     each hour. This will be further limited by the output capacity.
      #
      # Returns an array containing the amount stored in the battery in each hour.
      def self.run(
        data,
        input_capacity:,
        output_capacity:,
        volume:,
        charging_limit: nil,
        discharging_limit: nil,
        lookbehind: 72,
        output_efficiency: 1.0
      )
        # Creates curves which describe the maximum amount by which the battery can charge or
        # discharge in each hour.
        charging_target = build_target(charging_limit, input_capacity, data.length)
        discharging_target = build_target(discharging_limit, output_capacity, data.length)

        # All values for the year converted into a frame.
        frames = data.to_a.map.with_index { |value, index| Frame.new(index, value) }

        # Contains all hours where there is room to discharge, sorted in ascending order (hour of
        # largest value is last).
        charge_frames = frames.select { |f| discharging_target[f.index].positive? }.sort_by{ |f| [f.value, f.index] }

        # Keeps track of how much energy is stored in each hour.
        reserve = Numo::DFloat.zeros(data.length)

        while charge_frames.length.positive?
          max_frame = charge_frames.pop

          # Eventually will contain the amount of energy to be discharged at the max frame.
          available_output_energy = discharging_target[max_frame.index]

          # The frame cannot be discharged any further.
          next if available_output_energy.zero?

          # Only charge from an hour whose value is 95% or less than the max frame value.
          # This effectively ensures that a discharge hour will not be matched to a charge
          # hour of roughly the same value.
          desired_low = max_frame.value * 0.95

          # Contains the hour within the lookbehind period with the minimum value.
          min_frame = nil

          # Find an hour where a charge can be placed.
          (max_frame.index - 1).downto(max_frame.index - 1 - lookbehind) do |min_index|
            # We've reached a frame where the battery is full; therefore neither it nor any earlier
            # frame will be able to charge.
            break if reserve[min_index] >= volume

            current = frames[min_index]

            # Limit charging by the remaining volume in the frame, combined with the
            # efficiency to ensure we have enough in reserve to account for the losses.
            available_output_energy = [
              (volume - reserve[min_index]) * output_efficiency,
              available_output_energy].min

            next unless available_output_energy.positive? &&
              charging_target[current.index].positive? &&
              (!min_frame || current.value < min_frame.value) &&
              current.value < desired_low

            min_frame = current
          end

          # We now have either the min frame, or nil in whihc case no optimization can be performed
          # on the max frame.
          next if min_frame.nil?

          # Limit discharging by input capacity left for charging
          available_output_energy = [
            (charging_target[min_frame.index] * output_efficiency),
            available_output_energy].min

          # The amount of energy to be discharged at the max frame.
          # Limited to 1/4 of the difference in order to assign frames back on to the stack to so
          # that their energy may be more fairly shared with other nearby frames.
          available_output_energy = [(max_frame.value - min_frame.value) / 4, available_output_energy].min

          next if available_output_energy < 1e-5

          input_energy = available_output_energy / output_efficiency

          # Add the charge and discharge to the reserve.
          if min_frame.index > max_frame.index
            # Wrapped from end of the year to the beginning
            reserve[min_frame.index..-1] += input_energy
            reserve[0...max_frame.index] += input_energy if max_frame.index.positive?
          else
            reserve[min_frame.index...max_frame.index] += input_energy
          end

          min_frame.value += input_energy
          max_frame.value -= available_output_energy

          charging_target[min_frame.index] -= input_energy
          discharging_target[min_frame.index] = 0 # Frame is no longer allowed to discharge.

          discharging_target[max_frame.index] -= available_output_energy
          charging_target[max_frame.index] = 0 # Frame is no longer allowed to charge.

          next unless discharging_target[max_frame.index].positive?

          # The max frame can be further discharged. Add it back on the stack.
          insert_at = charge_frames.bsearch_index { |v| v.value > max_frame.value }

          if insert_at
            charge_frames.insert(insert_at - 1, max_frame)
          else
            charge_frames.push(max_frame)
          end
        end

        reserve
      end

      # Builds a target curve for the battery to charge or discharge, limited by the given capacity.
      #
      # If an existing curve is given, it will be clipped to the capacity.
      #
      # Returns a Numo::DFloat.
      def self.build_target(target_curve, capacity, length)
        if target_curve
          Numo::DFloat.cast(target_curve).clip(0.0, capacity)
        else
          Numo::DFloat.cast([capacity] * length)
        end
      end

      private_class_method :build_target
    end
  end
end
