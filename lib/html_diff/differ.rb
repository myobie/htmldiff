# frozen_string_literal: true

require 'diff/lcs'

module HTMLDiff
  # Performs a LCS diff and joins consecutive operations of the same type,
  # including joining across whitespaces.
  module Differ
    extend self

    # Constants for array indices
    INDEX_ACTION = 0
    INDEX_OLD = 1
    INDEX_NEW = 2
    INDEX_WS = 3

    # Generate a simplified diff from two sequences
    #
    # @param old_tokens [Array<String>] tokens from the original text
    # @param new_tokens [Array<String>] tokens from the new text
    # @return [Array<Array>] array of [action, old_string, new_string] tuples
    def diff(old_tokens, new_tokens)
      ops = build_ops(old_tokens, new_tokens)
      result = []
      i = 0

      while i < ops.length
        # Start a new group
        curr = ops[i]
        action = curr[INDEX_ACTION]
        old_val = String.new(curr[INDEX_OLD] || '')
        new_val = String.new(curr[INDEX_NEW] || '')
        j = i + 1

        # Check for patterns
        while j < ops.length
          next_op = ops[j]

          if next_op[INDEX_ACTION] == action
            # Same operation type, append it
            old_val << next_op[INDEX_OLD] if next_op[INDEX_OLD]
            new_val << next_op[INDEX_NEW] if next_op[INDEX_NEW]
            j += 1
          elsif next_op[INDEX_WS] && action == ops[j + 1]&.[](INDEX_ACTION)
            # Whitespace followed by the same operation type, append both
            old_val << next_op[INDEX_OLD] if next_op[INDEX_OLD]
            old_val << ops[j + 1][INDEX_OLD] if ops[j + 1][INDEX_OLD]
            new_val << next_op[INDEX_NEW] if next_op[INDEX_NEW]
            new_val << ops[j + 1][INDEX_NEW] if ops[j + 1][INDEX_NEW]
            j += 2
          else
            # Different pattern, break
            break
          end
        end

        # Add the grouped operation
        result << finalize_op(action, old_val, new_val)

        # Move to the next unprocessed token
        i = j
      end

      result
    end

    private

    # Perform LCS sdiff
    def lcs_sdiff(old_tokens, new_tokens)
      Diff::LCS.sdiff(old_tokens, new_tokens)
    end

    # Convert to our format for easier processing
    def build_ops(old_tokens, new_tokens)
      lcs_sdiff(old_tokens, new_tokens).map do |diff|
        if diff.action == '='
          ['=', diff.old_element, diff.new_element, diff.old_element.strip.empty?]
        else
          ['!', diff.old_element || '', diff.new_element || '']
        end
      end
    end

    # Determine the final operation type
    def finalize_op(action, old_val, new_val)
      if action == '!'
        if old_val.empty?
          action = '+'
          old_val = nil
        elsif new_val.empty?
          action = '-'
          new_val = nil
        end
      end

      [action, old_val, new_val]
    end
  end
end
