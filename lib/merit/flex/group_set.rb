# frozen_string_literal: true

require 'forwardable'

module Merit
  module Flex
    # Stores pre-defined flexibility groups for a ParticipantSet.
    class GroupSet
      extend Forwardable
      def_delegators :@groups, :key?, :fetch, :[]

      def initialize
        @groups = {}
      end

      def define(group)
        @groups[group.key] = group
      end

      def fetch_or_define(key)
        @groups[key] ||= Flex::Group.new(key)
      end
    end
  end
end
