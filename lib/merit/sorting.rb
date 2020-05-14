# frozen_string_literal: true

module Merit
  module Sorting
    # Public: Receives a collection of participants, the method name which
    # returns the cost strategy, and an optional sorting block to be used if the
    # collection sorting is Variable.
    #
    # Returns a sorting for the collection.
    def self.for_collection(collection, &sorter)
      if collection.any? { |p| p.cost_strategy.variable? }
        Variable.new(collection, &sorter)
      else
        Fixed.new(collection)
      end
    end

    # Represents a collection of participants which are pre-sorted.
    class Fixed
      def initialize(collection = [])
        @collection = collection.dup
        @seen = Hash[@collection.zip([])]
      end

      def insert(item)
        unless @seen.key?(item)
          @collection.push(item)
          @seen[item] = nil
        end

        @collection
      end

      def at_point(*)
        @collection
      end
    end

    # Represents a collection of participants which are re-sorted each time
    # at_point is called. Note that the collection is sorted in-place to avoid
    # allocating new arrays.
    class Variable < Fixed
      # Public: Creates a Variable sorting, set up to sort the members by their
      # sortable cost in ascending order.
      #
      # Returns a Variable.
      def self.by_sortable_cost(collection = [])
        new(collection) do |part, point|
          part.cost_strategy.sortable_cost(point)
        end
      end

      # Public: Creates a Variable sorting, set up to sort the members by their
      # sortable cost in descending order.
      #
      # Returns a Variable.
      def self.by_sortable_cost_desc(collection = [])
        new(collection) do |part, point|
          -part.cost_strategy.sortable_cost(point)
        end
      end

      def initialize(collection = [], &sorter)
        super(collection)

        @sorter = sorter
        @last_sorting_point = nil
      end

      def at_point(point)
        if point != @last_sorting_point
          @collection.sort_by! do |participant|
            @sorter.call(participant, point)
          end

          @last_sorting_point = point
        end

        @collection
      end
    end
  end
end
