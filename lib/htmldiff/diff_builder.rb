# frozen_string_literal: true

module HTMLDiff
  # The DiffBuilder class builds an HTML diff from two text inputs
  # by finding the differences and wrapping them in appropriate HTML tags
  class DiffBuilder
    def initialize(old_version, new_version)
      @old_version = old_version
      @new_version = new_version
      @content = []
    end

    # Build and return the HTML diff
    # @return [String] the HTML diff of the two versions
    def build
      tokenize_inputs
      operations = OperationGenerator.generate_operations(@old_words, @new_words)
      operations.each { |op| apply_operation(op) }
      @content.join
    end

    private

    # Tokenize the input strings
    def tokenize_inputs
      @old_words = Tokenizer.tokenize(@old_version)
      @new_words = Tokenizer.tokenize(@new_version)
    end

    # Apply an operation to the content
    # @param operation [Operation] the operation to apply
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
    # @param operation [Operation] the insert operation
    # @param css_class [String] the CSS class for the tag
    def insert_with_tag(operation, css_class = 'diffins')
      words = @new_words[operation.start_in_new...operation.end_in_new]
      insert_words_with_tag('ins', css_class, words)
    end

    # Delete words with appropriate tags
    # @param operation [Operation] the delete operation
    # @param css_class [String] the CSS class for the tag
    def delete_with_tag(operation, css_class = 'diffdel')
      words = @old_words[operation.start_in_old...operation.end_in_old]
      insert_words_with_tag('del', css_class, words)
    end

    # Copy matching words directly into the content
    # @param operation [Operation] the equal operation
    def copy_matching_words(operation)
      @content += @new_words[operation.start_in_new...operation.end_in_new]
    end

    # Extract consecutive words that match a condition
    # @param words [Array<String>] the words to process
    # @yield [word] Block that returns true if the word matches the condition
    # @return [Array<String>] the extracted words
    def extract_consecutive_words(words, &condition)
      index = words.find_index { |word| !condition.call(word) } || words.length
      words.slice!(0, index)
    end

    # Insert words with the specified tag, handling HTML tags appropriately
    # @param tag_name [String] the name of the HTML tag to use
    # @param css_class [String] the CSS class for the tag
    # @param words [Array<String>] the words to insert
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
    # @param text [String] the text to wrap
    # @param tag_name [String] the name of the HTML tag
    # @param css_class [String] the CSS class for the tag
    # @return [String] the wrapped text
    def wrap_with_tag(text, tag_name, css_class)
      %(<#{tag_name} class="#{css_class}">#{text}</#{tag_name}>)
    end
  end
end
