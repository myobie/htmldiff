# frozen_string_literal: true

module HTMLDiff
  module Formatters
    # The DelInsFormatter renders the diff as HTML with <del> and <ins> tags.
    module DelInsFormatter
      extend self

      # Format a sequence of changes from LcsDiff into HTML
      #
      # @param changes [Array<Array>] Array of [action, old_string, new_string] tuples,
      #   where action is one of '=' (equal), '-' (remove), '+' (add), or '!' (replace)
      # @return [String] HTML formatted diff
      def format(changes)
        changes.each_with_object(+'') do |(action, old_string, new_string), content|
          case action
          when '=' # equal
            content << new_string if new_string
          when '-' # remove
            content << html_tag('del', 'diffdel', old_string)
          when '+' # add
            content << html_tag('ins', 'diffins', new_string)
          when '!' # replace
            content << html_tag('del', 'diffmod', old_string)
            content << html_tag('ins', 'diffmod', new_string)
          end
        end
      end

      private

      # Render an HTML tag
      #
      # @param tag_name [String] The name of the HTML tag to use
      # @param css_class [String] The CSS class for the tag
      # @param content [String] The words to insert
      # @return [String] HTML markup with appropriate tags
      def html_tag(tag_name, css_class, content)
        return '' unless content

        %(<#{tag_name} class="#{css_class}">#{content}</#{tag_name}>)
      end
    end
  end
end
