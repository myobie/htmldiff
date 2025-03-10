# frozen_string_literal: true

module HTMLDiff
  # The OperationGenerator module is responsible for generating the operations needed
  # to transform one sequence of tokens into another.
  module OperationGenerator
    extend self

    # Generate operations to transform old_words into new_words
    #
    # @param old_words [Array<String>] tokens from the original text
    # @param new_words [Array<String>] tokens from the new text
    # @return [Array<Operation>] sequence of operations
    def generate_operations(old_words, new_words)
      position_in_old = position_in_new = 0
      operations = []

      # Index all positions of each token in the new sequence for faster lookup
      word_indices = index_words(new_words)

      # Find all matching blocks between the two versions
      matches = find_matching_blocks(old_words, new_words, word_indices)

      # Add a sentinel match at the end to handle unmatched tails
      sentinel_match = Match.new(old_words.size, new_words.size, 0)
      matches << sentinel_match

      matches.each do |match|
        # Determine what to do with the text between our current position
        # and the start of this match
        if position_in_old < match.start_in_old || position_in_new < match.start_in_new
          operation = create_operation_before_match(
            position_in_old, match.start_in_old,
            position_in_new, match.start_in_new
          )
          operations << operation unless operation.nil?
        end

        # If this is an actual match (not the sentinel), create an 'equal' operation
        if match.size > 0
          equal_operation = Operation.new(
            :equal,
            match.start_in_old, match.end_in_old,
            match.start_in_new, match.end_in_new
          )
          operations << equal_operation
        end

        # Update positions to the end of this match
        position_in_old = match.end_in_old
        position_in_new = match.end_in_new
      end

      operations
    end

    private

    # Create an index mapping each word to all positions where it appears
    #
    # @param words [Array<String>] sequence of tokens
    # @return [Hash] hash mapping each token to array of positions
    def index_words(words)
      indices = Hash.new { |h, word| h[word] = [] }
      words.each_with_index { |word, i| indices[word] << i }
      indices
    end

    # Find all matching blocks between two sequences of tokens
    #
    # @param old_words [Array<String>] tokens from the original text
    # @param new_words [Array<String>] tokens from the new text
    # @param word_indices [Hash] index of positions for tokens in new_words
    # @return [Array<Match>] array of matching blocks
    def find_matching_blocks(old_words, new_words, word_indices)
      matching_blocks = []
      find_matching_blocks_recursive(
        old_words, new_words, word_indices,
        0, old_words.size, 0, new_words.size,
        matching_blocks
      )
      matching_blocks
    end

    # Recursively find matching blocks within a specified range
    #
    # @param old_words [Array<String>] tokens from the original text
    # @param new_words [Array<String>] tokens from the new text
    # @param word_indices [Hash] index of positions for tokens in new_words
    # @param start_in_old [Integer] start position in old_words
    # @param end_in_old [Integer] end position in old_words
    # @param start_in_new [Integer] start position in new_words
    # @param end_in_new [Integer] end position in new_words
    # @param matching_blocks [Array<Match>] array to store matches
    def find_matching_blocks_recursive(
      old_words, new_words, word_indices,
      start_in_old, end_in_old, start_in_new, end_in_new,
      matching_blocks
    )
      # Find the largest matching block within the specified range
      match = find_largest_match(old_words, word_indices, start_in_old, end_in_old, start_in_new, end_in_new)
      return unless match

      # If there's text before the match, recursively find matches in that range
      if start_in_old < match.start_in_old && start_in_new < match.start_in_new
        find_matching_blocks_recursive(
          old_words, new_words, word_indices,
          start_in_old, match.start_in_old,
          start_in_new, match.start_in_new,
          matching_blocks
        )
      end

      # Add the current match
      matching_blocks << match

      # If there's text after the match, recursively find matches in that range
      if match.end_in_old < end_in_old && match.end_in_new < end_in_new
        find_matching_blocks_recursive(
          old_words, new_words, word_indices,
          match.end_in_old, end_in_old,
          match.end_in_new, end_in_new,
          matching_blocks
        )
      end
    end

    # Find the largest matching block of text within the specified range
    #
    # @param old_words [Array<String>] tokens from the original text
    # @param word_indices [Hash] index of positions for tokens in new_words
    # @param start_in_old [Integer] start position in old_words
    # @param end_in_old [Integer] end position in old_words
    # @param start_in_new [Integer] start position in new_words
    # @param end_in_new [Integer] end position in new_words
    # @return [Match, nil] the largest match found, or nil if none
    def find_largest_match(old_words, word_indices, start_in_old, end_in_old, start_in_new, end_in_new)
      best_match_in_old = start_in_old
      best_match_in_new = start_in_new
      best_match_size = 0

      # Track the length of matches ending at each position
      match_length_at = Hash.new { |h, index| h[index] = 0 }

      # Iterate through each word in the old version
      (start_in_old...end_in_old).each do |index_in_old|
        old_word = old_words[index_in_old]
        new_match_length_at = Hash.new { |h, index| h[index] = 0 }

        # For each position where this word appears in the new version
        word_indices[old_word].each do |index_in_new|
          next if index_in_new < start_in_new
          break if index_in_new >= end_in_new

          # Length of the match ending at these indices is 1 + length of match ending at previous indices
          new_match_length = match_length_at[index_in_new - 1] + 1
          new_match_length_at[index_in_new] = new_match_length

          # If this is the longest match so far, update the best match
          if new_match_length > best_match_size
            best_match_in_old = index_in_old - new_match_length + 1
            best_match_in_new = index_in_new - new_match_length + 1
            best_match_size = new_match_length
          end
        end

        match_length_at = new_match_length_at
      end

      return nil if best_match_size == 0
      Match.new(best_match_in_old, best_match_in_new, best_match_size)
    end

    # Determine what operation to perform for the text before a match
    #
    # @param start_in_old [Integer] start position in old_words
    # @param end_in_old [Integer] end position in old_words
    # @param start_in_new [Integer] start position in new_words
    # @param end_in_new [Integer] end position in new_words
    # @return [Operation, nil] the operation to perform, or nil if none
    def create_operation_before_match(start_in_old, end_in_old, start_in_new, end_in_new)
      if start_in_old < end_in_old && start_in_new < end_in_new
        # Text was changed in both versions
        Operation.new(:replace, start_in_old, end_in_old, start_in_new, end_in_new)
      elsif start_in_old < end_in_old
        # Text was deleted from old version
        Operation.new(:delete, start_in_old, end_in_old, start_in_new, end_in_new)
      elsif start_in_new < end_in_new
        # Text was inserted in new version
        Operation.new(:insert, start_in_old, end_in_old, start_in_new, end_in_new)
      end
    end
  end
end
