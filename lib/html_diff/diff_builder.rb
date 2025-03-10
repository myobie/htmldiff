# frozen_string_literal: true

require 'diff/lcs'

module HTMLDiff
  # Performs a LCS diff and joins consecutive operations of the same type.
  module DiffBuilder
    extend self

    # Generate a simplified diff from two sequences
    #
    # @param old_tokens [Array<String>] tokens from the original text
    # @param new_tokens [Array<String>] tokens from the new text
    # @return [Array<Array>] array of [action, old_string, new_string] tuples
    def diff(old_tokens, new_tokens)
      changes = Diff::LCS.sdiff(old_tokens, new_tokens)
      last_action = nil
      changes.each_with_object([]) do |change, result|
        last = result.last
        if change.action == last_action
          last[1] << change.old_element if last[1]
          last[2] << change.new_element if last[2]
        elsif (change.action == '+' && last_action == '-') || (change.action == '-' && last_action == '+')
          last[0] = '!'
          last[1] ||= +''
          last[2] ||= +''
          last[1] << change.old_element if change.old_element
          last[2] << change.new_element if change.new_element
        elsif last_action == '!' && %w[- +].include?(change.action)
          last[1] << change.old_element if change.old_element
          last[2] << change.new_element if change.new_element
        else
          result << [change.action, change.old_element&.dup, change.new_element&.dup]
          last_action = change.action
        end
      end
    end
  end
end
