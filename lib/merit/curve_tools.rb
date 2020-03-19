# frozen_string_literal: true

module Merit
  # This monstrosity dynamically defines methods on itself as an optimised way
  # to sum the values in Merit curves.
  #
  # Typically this would be done as:
  #
  #   [Merit::Curve.new(...), Merit::Curve.new(...)].reduce(:+)
  #
  # Instead, CurveTools creates a method on itself like so:
  #
  #   def add_curves_2(c0, c1)
  #     ::Merit::Curve.new(Array.new(c0.length) do |index|
  #       c0[index] + c1[index]
  #     end
  #   end
  #
  # If there is no "adder" method for the number of curves given, the curves
  # will be partitioned into the largest groups possible in order to sum the
  # curves optimally. For example, adding 15 curves will run `add_curves_10` on
  # the first ten curves, `add_curves_5` on the remaining five, then
  # `add_curves_2` on the previous two results to get the final summed curve.
  #
  # Benchmarks:
  #
  #   Warming up --------------------------------------
  #         reduce     2.000  i/100ms
  #     add_curves    16.000  i/100ms
  #   Calculating -------------------------------------
  #         reduce     22.673  (+- 4.4%) i/s -    114.000 in 5.036311s
  #     add_curves    164.975  (+- 4.2%) i/s -    832.000 in 5.052981s
  module CurveTools
    class << self
      # Public: Combines two or more curves, creating a new curve where each
      # value is the sum of values in each provided curve.
      #
      # Use instead of `curves.reduce(:+)` when performance is needed.
      #
      # Returns a Merit::Curve.
      def add_curves(curves)
        case curves.length
        when 1 then curves.first
        when 2 then add_curves_2(*curves)
        when 3 then add_curves_3(*curves)
        when 4 then add_curves_4(*curves)
        when 5 then add_curves_5(*curves)
        when 10 then add_curves_10(*curves)
        when 20 then add_curves_20(*curves)
        else add_many(curves)
        end
      end

      private

      # Internal: Adds an arbitrary number of curves together using the largest
      # available adder methods.
      def add_many(curves)
        while curves.length > 1
          curves = curves
            .each_slice(partition_size(curves))
            .map { |partition| add_curves(partition) }
        end

        curves.first
      end

      # Internal: Creates a method which implements loop unrolling for adding
      # two or more Merit curves. See CurveTools.add_curves.
      #
      # Use `add_curves` as the public API to these dynamic methods.
      #
      # For example:
      #   define_curve_adder(3)
      #
      # Creates:
      #   # def add_curves_3(c0, c1, c2)
      #   #   ::Merit::Curve.new(Array.new(c0.length) do |index|
      #   #     c0[index] + c1[index] + c2[index]
      #   #   end)
      #   # end
      #
      # Returns the name of the generated method.
      def define_curve_adder(num_curves)
        params = Array.new(num_curves) { |i| "c#{i}" }
        param_list = params.join(', ')
        name = :"add_curves_#{num_curves}"

        instance_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name}(#{param_list})
            length = curves_length(#{param_list})

            ::Merit::Curve.new(Array.new(length) do |index|
              #{params.map { |p| "(#{p}[index] || 0.0)" }.join(' + ')}
            end)
          end

          private_class_method name
        RUBY

        name
      end

      def partition_size(curves)
        length = curves.length

        return 20 if length > 20
        return 10 if length > 10

        5
      end

      def curves_length(*curves)
        curves.detect { |c| c.length.positive? }&.length || 0
      end
    end

    define_curve_adder(2)
    define_curve_adder(3)
    define_curve_adder(4)
    define_curve_adder(5)
    define_curve_adder(10)
    define_curve_adder(20)
  end
end
