# frozen_string_literal: true

require 'diff/lcs'

module HTMLDiff
  # Performs a LCS diff and joins consecutive operations of the same type,
  # including joining across whitespaces.
  module Differ
    extend self

    # Constants for array indices
    DEFAULT_MERGE_THRESHOLD = 5
    INDEX_ACTION = 0
    INDEX_OLD = 1
    INDEX_NEW = 2
    INDEX_MERGEABLE = 3

    # Generate a simplified diff from two sequences
    #
    # @param old_tokens [Array<String>] tokens from the original text
    # @param new_tokens [Array<String>] tokens from the new text
    # @option :merge_threshold [Integer] Maximum string length of unchanged tokens
    #   to merge into neighboring changes. Value 0 merges only whitespace.
    #   Negative values disable merging. Default value is 5.
    # @return [Array<Array>] array of [action, old_string, new_string] tuples
    def diff(old_tokens, new_tokens, merge_threshold: nil)
      merge_threshold ||= DEFAULT_MERGE_THRESHOLD unless merge_threshold.is_a?(FalseClass)
      ops = lcs_sdiff(old_tokens, new_tokens)

      # First pass: Compact consecutive operations of the same type
      ops = compact_ops(ops)

      # Second pass: Flag mergeable "=" operations
      ops.each do |op|
        next unless op[INDEX_ACTION] == '='

        op << mergeable_op?(op[INDEX_OLD], merge_threshold)
      end

      # Third pass: Merge consecutive unchanged operations
      # Don't touch this code, it's optimized for performance.
      result = []
      i = 0
      while i < ops.length
        # Start a new group
        curr_op = ops[i]
        action = curr_op[INDEX_ACTION]
        old_val = String.new(curr_op[INDEX_OLD] || '')
        new_val = String.new(curr_op[INDEX_NEW] || '')
        j = i + 1

        # Check for patterns of the same operation type.
        while j < ops.size
          next_op = ops[j]

          if action == next_op[INDEX_ACTION]
            # Same operation type, append it
            old_val << next_op[INDEX_OLD]
            new_val << next_op[INDEX_NEW]
            j += 1
          elsif next_op[INDEX_MERGEABLE] && (next_next_op = ops[j + 1]) && (action == '!' || next_next_op[INDEX_ACTION] == '!')
            # Mergeable segment preceded or followed by a replacement, combine everything
            old_val << next_op[INDEX_OLD]
            old_val << next_next_op[INDEX_OLD]
            new_val << next_op[INDEX_NEW]
            new_val << next_next_op[INDEX_NEW]
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

    def compact_ops(changes)
      last = nil
      last_action = nil
      changes.each_with_object([]) do |change, result|
        curr_action = change.action
        curr_old = change.old_element
        curr_new = change.new_element
        if last_action == curr_action
          last[INDEX_OLD] << curr_old if curr_old
          last[INDEX_NEW] << curr_new if curr_new
        elsif last_action && last_action != '=' && curr_action != '='
          last[INDEX_ACTION] = '!'
          last[INDEX_OLD] << curr_old if curr_old
          last[INDEX_NEW] << curr_new if curr_new
        else
          result << (last = [curr_action, String.new(curr_old || ''), String.new(curr_new || '')])
          last_action = curr_action
        end
      end
    end

    # Perform LCS sdiff
    def lcs_sdiff(old_tokens, new_tokens)
      Diff::LCS.sdiff(old_tokens, new_tokens)
    end

    def mergeable_op?(str, merge_threshold)
      if !merge_threshold || merge_threshold < 0
        false
      elsif merge_threshold == 0
        str.strip.empty?
      else
        str.size <= merge_threshold || str.strip.empty?
      end
    end

    # Determine the final operation type
    def finalize_op(action, old_val, new_val)
      if old_val.empty?
        action = '+'
        old_val = nil
      elsif new_val.empty?
        action = '-'
        new_val = nil
      elsif action != '='
        action = '!'
      end

      [action, old_val, new_val]
    end
  end
end
