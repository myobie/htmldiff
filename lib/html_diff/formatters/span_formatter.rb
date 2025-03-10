# frozen_string_literal: true

require_relative 'generic_formatter'

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
        GenericFormatter.format(changes,
                                tag: 'span',
                                class_delete: 'diff-del',
                                class_insert: 'diff-ins',
                                class_replace_delete: 'diff-mod diff-del',
                                class_replace_insert: 'diff-mod diff-ins')
      end
    end
  end
end
