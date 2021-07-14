# frozen_string_literal: true

module Merit
  class ParticipantSet
    # Takes a participant set and builds the list of flexibles, grouping them as necessary.
    module FlexListBuilder
      module_function

      # Public: Given a ParticipantSet, extracts the list of Flex participants and creates a list
      # for use in the calculation.
      #
      # Participants belonging to a defined group will be added to the appropriate group, while
      # groups with only a single member will be replaced with that member.
      def build(set)
        build_list(set.select(&:flex?), set.flex_groups)
          .map { |part| part.respond_to?(:simplify) ? part.simplify : part }
          .uniq
      end

      def build_list(flex, groups)
        flex.each_with_object([]) do |part, set|
          if part.group
            build_for_group(set, part, groups[part.group])
          else
            set.push(part)
          end
        end
      end

      private_class_method :build_list

      def build_for_group(collection, part, group)
        if collection.last && collection.last.key == part.group
          # The group is already present in the collection; add the participant to the group.
          collection.last.insert(part)
        elsif group
          group.insert(part)
          collection.push(group)
        else
          # Participant belongs to an undefined group; just add it to the collection.
          collection.push(part)
        end
      end

      private_class_method :build_for_group
    end
  end
end
