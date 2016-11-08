module Merit
  class CollectionTable
    attr_reader :collection, :attrs

    # Creates a new infotable
    def initialize(collection, attrs)
      @collection = collection
      @attrs      = attrs
    end

    def table
      Terminal::Table.new do |table|
        table.headings = attrs

        collection.each do |element|
          table << attrs.map { |a| round_if_number(element.send(a)) }
        end
      end
    end

    def round_if_number(object, precision = 0)
      if object.is_a?(Float)
        object.round(precision)
      else
        object
      end
    end

    def draw!
      puts table
    end
  end
end
