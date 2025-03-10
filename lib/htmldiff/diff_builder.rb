# frozen_string_literal: true

module HTMLDiff
  class DiffBuilder
    def initialize(old_version, new_version)
      @old_version = old_version
      @new_version = new_version
      @content = []
    end

    def build
      tokenize_inputs
      index_new_words
      generate_operations.each { |op| apply_operation(op) }
      @content.join
    end

    private

    def tokenize_inputs
      @old_words = Tokenizer.tokenize(@old_version)
      @new_words = Tokenizer.tokenize(@new_version)
    end

    def index_new_words
      # Create a hash mapping each word to all positions where it appears in new_words
      @word_indices = Hash.new { |h, word| h[word] = [] }
      @new_words.each_with_index { |word, i| @word_indices[word] << i }
    end

    # Generate a sequence of operations (insert, delete, replace, equal) that
    # transforms old_words into new_words
    def generate_operations
      position_in_old = position_in_new = 0
      operations = []

      # Find all matching blocks between the two versions
      matches = find_matching_blocks

      # Add a sentinel match at the end to handle unmatched tails
      sentinel_match = Match.new(@old_words.size, @new_words.size, 0)
      matches << sentinel_match

      matches.each do |match|
        # Determine what to do with the text between our current position
        # and the start of this match
        if position_in_old < match.start_in_old || position_in_new < match.start_in_new
          operation = create_operation_before_match(
            position_in_old, match.start_in_old,
            position_in_new, match.start_in_new
          )
          operations << operation if operation
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

    # Determine what operation to perform for the text before a match
    def create_operation_before_match(start_in_old, end_in_old, start_in_new, end_in_new)
      case
      when start_in_old < end_in_old && start_in_new < end_in_new
        Operation.new(:replace, start_in_old, end_in_old, start_in_new, end_in_new)
      when start_in_old < end_in_old
        Operation.new(:delete, start_in_old, end_in_old, start_in_new, end_in_new)
      when start_in_new < end_in_new
        Operation.new(:insert, start_in_old, end_in_old, start_in_new, end_in_new)
      end
    end

    # Find all blocks of text that match between old_words and new_words
    def find_matching_blocks
      matching_blocks = []
      find_matching_blocks_recursive(0, @old_words.size, 0, @new_words.size, matching_blocks)
      matching_blocks
    end

    # Recursively find matching blocks within a specified range
    def find_matching_blocks_recursive(start_in_old, end_in_old, start_in_new, end_in_new, matching_blocks)
      # Find the largest matching block within the specified range
      match = find_largest_match(start_in_old, end_in_old, start_in_new, end_in_new)
      return unless match

      # If there's text before the match, recursively find matches in that range
      if start_in_old < match.start_in_old && start_in_new < match.start_in_new
        find_matching_blocks_recursive(
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
          match.end_in_old, end_in_old,
          match.end_in_new, end_in_new,
          matching_blocks
        )
      end
    end

    # Find the largest matching block of text within the specified range
    def find_largest_match(start_in_old, end_in_old, start_in_new, end_in_new)
      best_match_in_old = start_in_old
      best_match_in_new = start_in_new
      best_match_size = 0

      # Track the length of matches ending at each position
      match_length_at = Hash.new { |h, index| h[index] = 0 }

      # Iterate through each word in the old version
      (start_in_old...end_in_old).each do |index_in_old|
        old_word = @old_words[index_in_old]
        new_match_length_at = Hash.new { |h, index| h[index] = 0 }

        # For each position where this word appears in the new version
        @word_indices[old_word].each do |index_in_new|
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

    # Apply an operation to the content
    def apply_operation(operation)
      case operation.action
      when :replace
        delete_with_tag(operation, 'diffmod')
        insert_with_tag(operation, 'diffmod')
      when :insert
        insert_with_tag(operation)
      when :delete
        delete_with_tag(operation)
      when :equal
        copy_matching_words(operation)
      else
        raise "Unknown operation: #{operation.action}"
      end
    end

    # Insert words with appropriate tags
    def insert_with_tag(operation, css_class = 'diffins')
      words = @new_words[operation.start_in_new...operation.end_in_new]
      insert_words_with_tag('ins', css_class, words)
    end

    # Delete words with appropriate tags
    def delete_with_tag(operation, css_class = 'diffdel')
      words = @old_words[operation.start_in_old...operation.end_in_old]
      insert_words_with_tag('del', css_class, words)
    end

    # Copy matching words directly into the content
    def copy_matching_words(operation)
      @content += @new_words[operation.start_in_new...operation.end_in_new]
    end

    # Extract consecutive words that match a condition
    def extract_consecutive_words(words, &condition)
      index = words.find_index { |word| !condition.call(word) } || words.length
      words.slice!(0, index)
    end

    # Insert words with the specified tag, handling HTML tags appropriately
    def insert_words_with_tag(tag_name, css_class, words)
      # Make a copy to avoid modifying the original array
      words_to_process = words.dup

      until words_to_process.empty?
        # Extract consecutive non-tag words or img tags
        non_tags = extract_consecutive_words(words_to_process) do |word|
          Tokenizer.img_tag?(word) || !Tokenizer.tag?(word)
        end

        unless non_tags.join.empty?
          @content << wrap_with_tag(non_tags.join, tag_name, css_class)
        end

        break if words_to_process.empty?

        # Extract consecutive HTML tags (other than img tags)
        tags = extract_consecutive_words(words_to_process) { |word| Tokenizer.tag?(word) }
        @content += tags
      end
    end

    # Wrap text with the specified HTML tag and class
    def wrap_with_tag(text, tag_name, css_class)
      %(<#{tag_name} class="#{css_class}">#{text}</#{tag_name}>)
    end
  end
end
