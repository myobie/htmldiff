# frozen_string_literal: true

module HTMLDiff
  module Formatters
    # The SpanFormatter renders the diff as HTML with <span> tags.
    module SpanFormatter
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
            content << span_tag('diff-remove', old_string)
          when '+' # add
            content << span_tag('diff-add', new_string)
          when '!' # replace
            content << span_tag('diff-replace diff-remove', old_string)
            content << span_tag('diff-replace diff-add', new_string)
          end
        end
      end

      private

      # Render an HTML tag
      #
      # @param css_class [String] The CSS class(es) for the tag
      # @param content [String] The words to insert
      # @return [String] HTML markup with appropriate tags
      def span_tag(css_class, content)
        return '' unless content
        %(<span class="#{css_class}">#{content}</span>)
      end
    end
  end
end
