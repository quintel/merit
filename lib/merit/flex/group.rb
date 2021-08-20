# frozen_string_literal: true

require 'forwardable'

module Merit
  module Flex
    # Wraps two or more flex technologies so that their capacities and assignments may be treated as
    # an aggregate.
    class Group
      extend Forwardable
      include Enumerable

      def_delegator :@collection, :each

      # Public: Given a Sorting containing flex technologies, returns an array of the technologies
      # grouped by price.
      #
      # Technologies which share a price in the given `point` will be wrapped inside a Group, while
      # those with a unique price will be included in the output array without any changes.
      #
      # Returns Array[Flex::Base | Flex::Group]
      def self.from_collection(collection, point = 0)
        groups = []
        last_cost = nil

        collection.at_point(point).each do |part|
          cost = part.cost_strategy.sortable_cost(point)

          if cost == last_cost
            groups.last.push(part)
          else
            groups.push([part])
          end

          last_cost = cost
        end

        groups.map! do |parts|
          parts.length > 1 ? new(parts) : parts[0]
        end

        groups
      end

      def initialize(collection)
        if collection.nil? || collection.empty?
          raise "Cannot create a #{self.class.name} with no members"
        end

        @collection = collection
      end

      def to_a
        @collection.dup
      end

      def key
        :anonymous_group
      end

      def cost_strategy
        @collection[0].cost_strategy
      end

      def inspect
        "#<#{self.class.name} (#{@collection.map(&:key).join(', ')})>"
      end

      def to_s
        "#{self.class.name}(#{@collection.map(&:key).join(', ')})"
      end

      def unused_input_capacity_at(point)
        @collection.sum do |part|
          part.unused_input_capacity_at(point)
        end
      end

      # Public: Assigns excess energy to the contained flex technologies, but only when they're
      # willing to pay greater than the current market price.
      def barter_at(point, amount, price)
        if cost_strategy.cost_at(point) > price
          assign_excess(point, amount)
        else
          0.0
        end
      end

      # Public: Assigns excess energy to the contained flex technologies. Energy is split fairly
      # between the participants based on their remaining input capacity.
      def assign_excess(point, amount)
        return 0.0 if amount.zero?

        total_capacity = unused_input_capacity_at(point)

        return 0.0 if total_capacity.zero?

        @collection.sum do |part|
          part.assign_excess(
            point,
            amount * (part.unused_input_capacity_at(point) / total_capacity)
          )
        end
      end
    end
  end
end
