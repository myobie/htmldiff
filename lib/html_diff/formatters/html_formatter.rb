# frozen_string_literal: true

module HTMLDiff
  module Formatters
    # Renders the diff as HTML with customizable tags and classes.
    module HtmlFormatter
      extend self

      # Format a sequence of changes from LcsDiff into HTML
      #
      # @param changes [Array<Array>] Array of [action, old_string, new_string] tuples,
      #   where action is one of '=' (equal), '-' (remove), '+' (add), or '!' (replace)
      # @option tag [String] HTML tag to use for all delete, insert, and replace
      #   nodes. Can be overridden by other options.
      # @option tag_delete [String] HTML tag to use for delete nodes (overrides :tag)
      # @option tag_insert [String] HTML tag to use for insert nodes (overrides :tag)
      # @option tag_replace [String] HTML tag to use for replace nodes (overrides
      #   :tag_delete, :tag_insert, and :tag)
      # @option tag_replace_delete [String] HTML tag to use for deleted content
      #   in replace nodes (overrides :tag_replace, :tag_delete, and :tag)
      # @option tag_replace_insert [String] HTML tag to use for inserted content
      #   in replace nodes (overrides :tag_replace, :tag_insert, and :tag)
      # @option tag_equal [String] HTML tag to use for equal content.
      #   If not specified, equal content is not wrapped in a tag.
      # @option class [String, Array<String>] The CSS class(es) to use for all
      #   deleted, inserted, and replace nodes. Can be overridden by other options.
      # @option class_delete [String, Array<String>] The CSS class(es) to use for
      #   deleted nodes (overrides :class)
      # @option class_insert [String, Array<String>] The CSS class(es) to use for
      #   inserted nodes (overrides :class)
      # @option class_replace [String, Array<String>] The CSS class(es) to use for
      #   replace nodes (overrides :class_delete, :class_insert, and :class)
      # @option class_replace_delete [String, Array<String>] The CSS class(es) to
      #   use for deleted content in replace nodes (overrides :class_replace,
      #   :class_delete, and :class)
      # @option class_replace_insert [String, Array<String>] The CSS class(es) to
      #   use for inserted content in replace nodes (overrides :class_replace,
      #   :class_insert, and :class)
      # @option class_equal [String, Array<String>] The CSS class(es) to use for
      #   equal content. If not specified, equal content is not wrapped in a tag.
      # @return [String] HTML formatted diff.
      def format(changes, **kwargs)
        changes.each_with_object(+'') do |(action, old_string, new_string), content|
          case action
          when '=' # equal
            next unless new_string

            content << (kwargs[:tag_equal] ? html_tag(kwargs[:tag_equal], kwargs[:class_equal], new_string) : new_string)
          when '-' # remove
            tag = kwargs[:tag_delete] || kwargs[:tag] || 'del'
            css_class = kwargs[:class_delete] || kwargs[:class]
            content << html_tag(tag, css_class, old_string) if old_string
          when '+' # add
            tag = kwargs[:tag_insert] || kwargs[:tag] || 'ins'
            css_class = kwargs[:class_insert] || kwargs[:class]
            content << html_tag(tag, css_class, new_string) if new_string
          when '!' # replace
            tag_delete = kwargs[:tag_replace_delete] || kwargs[:tag_replace] || kwargs[:tag_delete] || kwargs[:tag] || 'del'
            css_class_delete = kwargs[:class_replace_delete] || kwargs[:class_replace] || kwargs[:class_delete] || kwargs[:class]
            content << html_tag(tag_delete, css_class_delete, old_string) if old_string

            tag_insert = kwargs[:tag_replace_insert] || kwargs[:tag_replace] || kwargs[:tag_insert] || kwargs[:tag] || 'ins'
            css_class_insert = kwargs[:class_replace_insert] || kwargs[:class_replace] || kwargs[:class_insert] || kwargs[:class]
            content << html_tag(tag_insert, css_class_insert, new_string) if new_string
          end
        end
      end

      private

      # Render an HTML tag
      #
      # @param tag [String] HTML tag to use
      # @param css_class [String] The CSS class(es) for the tag
      # @param content [String] The words to insert
      # @return [String] HTML markup with appropriate tags
      def html_tag(tag, css_class, content)
        return '' unless content

        tag = tag.delete_prefix('<')
        tag = tag.delete_suffix('>')
        css_class = css_class.join(' ') if css_class.is_a?(Array)
        css_class = nil if css_class&.empty?
        "<#{tag}#{%( class="#{css_class}") if css_class}>#{content}</#{tag}>"
      end
    end
  end
end
