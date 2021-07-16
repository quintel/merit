# frozen_string_literal: true

require 'forwardable'

module Merit
  # Provides classes for optimally sorting collections of participants.
  module Sorting
    # Holds information about how to sort items in a Sorting.
    #
    # sort_key - A block which returns the key by which each item in the collection is sorted.
    # selector - A block which selects which items are variable (when returning true) or fixed (when
    #            returning false). This allows for significantly better performance in `Variable`
    #            when many items have non-variable pricing. Note that omitting the `selector` will
    #            cause all collections created in `Sorting.for_collection` to be `Fixed`.
    Config = Struct.new(:sort_key, :selector) do
      def self.default
        Config.new(->(el, _) { el }, ->(_) { false })
      end

      def any_variable?(collection)
        selector && collection.any? { |el| selector.call(el) }
      end
    end

    # Public: Receives a collection of participants, the method name which returns the cost
    # strategy, and an optional sorting block to be used if the collection sorting is Variable.
    #
    # Returns a sorting for the collection.
    def self.for_collection(collection, config = Config.default)
      if config.any_variable?(collection)
        Variable.new(collection, config)
      elsif config.sort_key.nil?
        Unsorted.new(collection)
      else
        Fixed.new(collection, config)
      end
    end

    # Public: Creates a Variable sorting, set up to sort the members by their sortable cost in
    # ascending order.
    #
    # Returns a Variable.
    def self.by_sortable_cost(collection = [])
      for_collection(
        collection,
        Config.new(
          ->(part, point) { part.cost_strategy.sortable_cost(point) },
          ->(part) { part.cost_strategy.variable? }
        )
      )
    end

    # Public: Creates a Variable sorting, set up to sort the members by their sortable cost in
    # descending order.
    #
    # Returns a Variable.
    def self.by_sortable_cost_desc(collection = [])
      for_collection(
        collection,
        Config.new(
          ->(part, point) { -part.cost_strategy.sortable_cost(point) },
          ->(part) { part.cost_strategy.variable? }
        )
      )
    end

    # Represents a collection of participants with no explicit order.
    #
    # Note that because collections store "seen" items in a hash, the performance of `initialize`
    # and `insert` is quite sensitive to the performance of `Item#hash` (where `Item` is the class
    # of an object stored in the collection).
    class Unsorted
      extend Forwardable
      include Enumerable

      def_delegators :@collection, :each, :empty?, :first, :length

      def initialize(collection = [])
        @collection = collection.dup
        @seen = @collection.zip([]).to_h
      end

      def insert(item)
        unless @seen.key?(item)
          @collection.push(item)
          @seen[item] = nil
        end

        self
      end

      def at_point(_point)
        @collection
      end

      def sortable?
        false
      end

      def to_a
        @collection.dup
      end

      def inspect
        "#<#{self.class.name} collection=#{@collection.inspect}>"
      end

      alias_method :to_s, :inspect
    end

    # Represents a collection of participants which are will be sorted once, with that order reused
    # for every point in the calculation.
    class Fixed < Unsorted
      def initialize(collection = [], config = Config.default)
        raise(SortBlockRequired, self.class.name) unless config.sort_key

        super(collection)

        @config = config
        @has_sorted = false
      end

      def at_point(_point)
        sort_collection(0) unless @has_sorted
        @collection
      end

      def sortable?
        true
      end

      # Converts the Fixed to a Variable.
      def to_variable
        Variable.new(@collection, @config)
      end

      private

      def sort_collection(point)
        @has_sorted = true
        i = 0

        @collection.sort_by! do |participant|
          [@config.sort_key.call(participant, point), i += 1]
        end
      end
    end

    # Represents a collection of participants which are re-sorted each time at_point is called. Note
    # that the collection is sorted in-place to avoid allocating new arrays.
    #
    # Sorting collections every hour is enormously slower than doing so only once; use this with
    # care!
    #
    # `Variable` partitions the items into two separate sub-arrays: one for containing
    # variably-priced items, for which the selector returns true, and another containing items with
    # a constant price. This allows the collection of fixed-price items to be sorted only once.
    #
    # In each call to `at_point`, the collection is emptied and repopulated with the fixed-price
    # items. The variable-priced items are then inserted into the collection using a binary search.
    #
    # In a typical case, this results in much improved performance over sorting the entire
    # collection every time. With 40 items, 5 of which have variably pricing, calling `at_point`
    # 8760 times, once for each hour in the year:
    #
    #   * Fixed collection: 1707.8 i/s
    #   * Variable collection, resorting everything: 10.7 i/s
    #   * Variable collection, partition and binary search insert: 28.4 i/s
    #
    # When the Variable contains only varible-priced items, binary search insert performs roughly
    # the same as simply resorting the whole collection. With 5 variable items:
    #
    #   * Resorting everything: 64.7 i/s
    #   * Partition and binary search insert: 69.5 i/s
    #
    # Variable will fall back to simple `sort_by` when it contains 33% or more variable-priced items
    # as this offers better performance in that
    #
    # It is essential that the config.sort_key return consistently ordered values for the
    # fixed-price items. A sort_key which ordered the fixed-price items incorrectly (for example
    # `->(*) { rand }`) will result in the binary search inserting items in incorrect positions.
    class Variable < Fixed
      # If no default selector is provided (to partition the collection into fixed and variable
      # priced items) then all items are considered variable.
      DEFAULT_SELECTOR = ->(_) { true }

      # Always use binary search insert when the collection has a small number of items.
      SIMPLE_SORT_LENGTH_THRESHOLD = 10

      # When there are many more variable items than fixed, binary search insert becomes
      # significantly slower than using `sort_by` on the whole collection. This seems to occur when
      # there is one or two variables for every fixed; this varies slightly depending on the size of
      # the collection. The threshold determines at what point Variable switches to using `sort_by`.
      SIMPLE_SORT_VARIABLE_THRESHOLD = 1.5

      def initialize(collection = [], config = Config.default)
        super
        @last_sorting_point = nil
        @variable, fixed = collection.partition { |part| selector.call(part) }

        # Pre-sort the fixed-price items.
        @fixed = Fixed.new(fixed, config).at_point(0)

        set_simple_sort_state
      end

      def insert(item)
        unless @seen.key?(item)
          @collection.push(item)
          (selector.call(item) ? @variable : @fixed).push(item)

          @seen[item] = nil

          set_simple_sort_state
        end

        self
      end

      def at_point(point)
        if point != @last_sorting_point
          sort_collection(point)
          @last_sorting_point = point
        end

        @collection
      end

      def simple_sort?
        @simple_sort
      end

      def inspect
        super.gsub(/>$/, " simple_sort=#{@simple_sort}>")
      end

      private

      def selector
        @config.selector || DEFAULT_SELECTOR
      end

      def sort_collection(point)
        return perform_simple_sort(point) if @simple_sort

        sort_key = @config.sort_key

        @collection.clear
        @collection.concat(@fixed)

        @variable.each do |item|
          key = sort_key.call(item, point)

          insert_at = @collection.bsearch_index do |other|
            sort_key.call(other, point) > key
          end

          if insert_at
            @collection.insert(insert_at, item)
          else
            @collection.push(item)
          end
        end
      end

      # When the collection contains only variable-priced items, and they number 6 or greater, a
      # simple sort_by outperforms binary search insert.
      def perform_simple_sort(point)
        sort_key = @config.sort_key
        @collection.sort_by! { |part| sort_key.call(part, point) }
      end

      def set_simple_sort_state
        @simple_sort =
          @collection.length >= SIMPLE_SORT_LENGTH_THRESHOLD &&
          @fixed.length.to_f / @variable.length < SIMPLE_SORT_VARIABLE_THRESHOLD
      end
    end
  end
end
