# frozen_string_literal: true

module Merit
  # Contains methods for reading and loading example merit orders exported from ETEngine.
  module Examples
    module_function

    def load(path)
      build(read(path))
    end

    # Public: Reads a stub file which defines all the attributes for participants in a Merit order
    # and returns an array of procs which will initialize each participant.
    def read(path)
      require 'yaml'
      require 'objspace'

      contents = File.read(path)
      contents = Zlib::Inflate.inflate(contents) if path.end_with?('gz')

      permitted_classes = [
        Symbol,
        *ObjectSpace.each_object(Class).select do |klass|
          klass <= Merit::Participant || klass <= Merit::Flex::Reserve || klass <= Merit::Curve
        end
      ]

      YAML.safe_load(contents, aliases: true, permitted_classes: permitted_classes).map do |part|
        opts = part[:opts].transform_values do |value|
          value.is_a?(Array) ? Merit::Curve.new(value) : value
        end

        if part[:type].name.start_with?('Merit::User')
          -> { Merit::User.create(opts) }
        else
          -> { part[:type].new(opts.merge(reserve_class: Merit::Flex::SimpleReserve)) }
        end
      end
    end

    # Public: Takes the array of participant creators build with `Merit.read_stub` and returns a new
    # uncalculated merit order.
    def build(participant_creators)
      order = Merit::Order.new

      participant_creators.each do |creator|
        order.add(creator.call)
      end

      order
    end
  end
end
