# frozen_string_literal: true

module HTMLDiff
  # The OutputFormatter module handles the creation of HTML markup
  # for displaying differences between two texts
  module OutputFormatter
    extend self

    # Format a sequence of operations into HTML
    #
    # @param operations [Array<Operation>] operations to format
    # @param old_words [Array<String>] tokens from the original text
    # @param new_words [Array<String>] tokens from the new text
    # @return [String] HTML formatted diff
    def format(operations, old_words, new_words)
      content = []

      operations.each do |operation|
        case operation.action
        when :replace
          content << delete_with_tag(operation, old_words, 'diffmod')
          content << insert_with_tag(operation, new_words, 'diffmod')
        when :insert
          content << insert_with_tag(operation, new_words)
        when :delete
          content << delete_with_tag(operation, old_words)
        when :equal
          content += new_words[operation.start_in_new...operation.end_in_new]
        else
          raise "Unknown operation: #{operation.action}"
        end
      end

      content.join
    end

    private

    # Create HTML for inserted words
    #
    # @param operation [Operation] the insert operation
    # @param words [Array<String>] the words to insert
    # @param css_class [String] the CSS class for the tag
    # @return [String] HTML markup for the inserted words
    def insert_with_tag(operation, words, css_class = 'diffins')
      words_slice = words[operation.start_in_new...operation.end_in_new]
      insert_words_with_tag('ins', css_class, words_slice)
    end

    # Create HTML for deleted words
    #
    # @param operation [Operation] the delete operation
    # @param words [Array<String>] the words to delete
    # @param css_class [String] the CSS class for the tag
    # @return [String] HTML markup for the deleted words
    def delete_with_tag(operation, words, css_class = 'diffdel')
      words_slice = words[operation.start_in_old...operation.end_in_old]
      insert_words_with_tag('del', css_class, words_slice)
    end

    # Extract consecutive words that match a condition
    #
    # @param words [Array<String>] the words to process
    # @yield [word] Block that returns true if the word matches the condition
    # @return [Array<String>] the extracted words
    def extract_consecutive_words(words, &condition)
      index = words.find_index { |word| !condition.call(word) } || words.length
      words.slice!(0, index)
    end

    # Insert words with the specified tag, handling HTML tags appropriately
    #
    # @param tag_name [String] the name of the HTML tag to use
    # @param css_class [String] the CSS class for the tag
    # @param words [Array<String>] the words to insert
    # @return [String] HTML markup with appropriate tags
    def insert_words_with_tag(tag_name, css_class, words)
      result = []
      # Make a copy to avoid modifying the original array
      words_to_process = words.dup

      until words_to_process.empty?
        # Extract consecutive non-tag words or img tags
        non_tags = extract_consecutive_words(words_to_process) do |word|
          Tokenizer.img_tag?(word) || !Tokenizer.tag?(word)
        end

        unless non_tags.join.empty?
          result << wrap_with_tag(non_tags.join, tag_name, css_class)
        end

        break if words_to_process.empty?

        # Extract consecutive HTML tags (other than img tags)
        tags = extract_consecutive_words(words_to_process) { |word| Tokenizer.tag?(word) }
        result += tags
      end

      result.join
    end

    # Wrap text with the specified HTML tag and class
    #
    # @param text [String] the text to wrap
    # @param tag_name [String] the name of the HTML tag
    # @param css_class [String] the CSS class for the tag
    # @return [String] the wrapped text
    def wrap_with_tag(text, tag_name, css_class)
      %(<#{tag_name} class="#{css_class}">#{text}</#{tag_name}>)
    end
  end
end
