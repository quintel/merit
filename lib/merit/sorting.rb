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
        Fixed.new(collection, &sorter)
      end
    end

    # Public: Creates a Variable sorting, set up to sort the members by their
    # sortable cost in ascending order.
    #
    # Returns a Variable.
    def self.by_sortable_cost(collection = [])
      for_collection(collection) do |part, point|
        part.cost_strategy.sortable_cost(point)
      end
    end

    # Public: Creates a Variable sorting, set up to sort the members by their
    # sortable cost in descending order.
    #
    # Returns a Variable.
    def self.by_sortable_cost_desc(collection = [])
      for_collection(collection) do |part, point|
        -part.cost_strategy.sortable_cost(point)
      end
    end

    # Represents a collection of participants which are pre-sorted.
    class Fixed
      def initialize(collection = [], &sorter)
        @collection = collection.dup
        @sorter = sorter

        @seen = Hash[@collection.zip([])]
        @has_sorted = false
      end

      def insert(item)
        unless @seen.key?(item)
          @collection.push(item)
          @seen[item] = nil
        end

        @collection
      end

      def at_point(*)
        sort_collection(nil) if !@has_sorted && @sorter
        @collection
      end

      def sortable?
        !@sorter.nil?
      end

      def to_a
        @collection.dup
      end

      # Converts the Fixed to a Variable.
      def to_variable
        Variable.new(@collection, &@sorter)
      end

      def inspect
        "#<#{self.class.name} sorter=#{@sorter.inspect} " \
          "collection=#{@collection.inspect}>"
      end

      alias_method :to_s, :inspect

      private

      def sort_collection(point)
        @has_sorted = true

        @collection.sort_by! do |participant|
          @sorter.call(participant, point)
        end
      end
    end

    # Represents a collection of participants which are re-sorted each time
    # at_point is called. Note that the collection is sorted in-place to avoid
    # allocating new arrays.
    class Variable < Fixed
      def initialize(collection = [], &sorter)
        raise SortBlockRequired if sorter.nil?

        super
        @last_sorting_point = nil
      end

      def at_point(point)
        if point != @last_sorting_point
          sort_collection(point)
          @last_sorting_point = point
        end

        @collection
      end
    end
  end
end
