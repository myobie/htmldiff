# frozen_string_literal: true

require 'diff/lcs'

module HTMLDiff
  # Performs a LCS diff and joins consecutive operations of the same type,
  # including joining across whitespaces.
  module Differ
    extend self

    # Generate a simplified diff from two sequences
    #
    # @param old_tokens [Array<String>] tokens from the original text
    # @param new_tokens [Array<String>] tokens from the new text
    # @return [Array<Array>] array of [action, old_string, new_string] tuples
    def diff(old_tokens, new_tokens)
      # Get the raw diff from Diff::LCS
      diffs = Diff::LCS.sdiff(old_tokens, new_tokens)

      # Convert to our format for easier processing
      ops = []
      diffs.each do |diff|
        case diff.action
        when '='
          ops << {op: '=', old: diff.old_element, new: diff.new_element, ws: diff.old_element.strip.empty?}
        when '+'
          ops << {op: '!', old: '', new: diff.new_element, ws: diff.new_element.empty?}
        when '-'
          ops << {op: '!', old: diff.old_element, new: '', ws: diff.old_element.empty?}
        when '!'
          ops << {op: '!', old: diff.old_element, new: diff.new_element, ws: diff.old_element.empty? && diff.new_element.empty?}
        end
      end

      # Process operations
      result = []
      i = 0

      while i < ops.length
        # Start a new group
        curr = ops[i]
        op = curr[:op]
        old_val = curr[:old]
        new_val = curr[:new]
        j = i + 1

        # Check for patterns
        while j < ops.length
          next_op = ops[j]

          if next_op[:op] == op
            # Same operation type, include it
            old_val += next_op[:old] if next_op[:old]
            new_val += next_op[:new] if next_op[:new]
            j += 1
          elsif next_op[:ws] && j + 1 < ops.length && ops[j + 1][:op] == op
            # Whitespace followed by the same operation type, include both
            old_val += next_op[:old] + ops[j + 1][:old] if next_op[:old] && ops[j + 1][:old]
            new_val += next_op[:new] + ops[j + 1][:new] if next_op[:new] && ops[j + 1][:new]
            j += 2
          else
            # Different pattern, break
            break
          end
        end

        # Determine the final operation type
        final_op = op
        if op == '!'
          if old_val.empty? || old_val.nil?
            final_op = '+'
            old_val = nil
          elsif new_val.empty? || new_val.nil?
            final_op = '-'
            new_val = nil
          end
        end

        # Add the grouped operation
        result << [final_op, old_val, new_val]

        # Move to the next unprocessed token
        i = j
      end

      result
    end
  end
end
