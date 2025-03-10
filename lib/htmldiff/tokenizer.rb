# frozen_string_literal: true

module HTMLDiff
  module Tokenizer
    extend self

    # The languages here are those that typically use space delimiters between words.
    # The characters @.- are added for email support, which could potentially be extracted to a
    # specialized function.
    WORDCHAR_REGEXP = /[\p{Latin}\p{Greek}\p{Cyrillic}\p{Arabic}\p{Hebrew}\p{Devanagari}\p{Hangul}\p{Armenian}\p{Georgian}\p{Ethiopic}\p{Khmer}\p{Lao}\p{Myanmar}\p{Sinhala}\p{Tamil}\p{Telugu}\p{Kannada}\p{Malayalam}\p{Tibetan}\p{Mongolian}\d@#.-]/i

    # Regular expressions for special entities
    URL_REGEXP = %r{(https?://|www\.)[^\s<>"']+}i
    EMAIL_REGEXP = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/i
    # PHONE_REGEXP = /(?:\+\d{1,3}[- ]?)?\(?(?:\d{1,4})\)?[- ]?(?:\d{1,4})[- ]?(?:\d{1,4})/
    HTML_ENTITY_REGEXP = /&([a-zA-Z0-9]+|#[0-9]{1,6}|#x[0-9a-fA-F]{1,6});/

    def tokenize(string)
      # Extract special entities first
      entities = extract_special_entities(string)

      # Process the string with entities treated as special tokens
      mode = :wordchar
      current_word = +''
      words = []
      position = 0

      while position < string.length
        # Check if current position is the start of an entity
        entity_match = entities.find { |_, start_pos, _| start_pos == position }

        if entity_match
          # Add any accumulated word before the entity
          words << current_word unless current_word.empty?
          current_word = +''

          # Add the entity as a token
          entity, _, end_pos = entity_match
          words << entity
          position = end_pos
          next
        end

        char = string[position]

        case mode
        when :tag
          if end_of_tag?(char)
            current_word << '>'
            words << current_word unless current_word.empty?
            current_word = +''
            mode = :wordchar
          else
            current_word << char
          end
        when :wordchar
          if start_of_tag?(char)
            words << current_word unless current_word.empty?
            current_word = +'<'
            mode = :tag
          elsif wordchar?(char)
            current_word << char
          else
            words << current_word unless current_word.empty?
            current_word = char
            mode = :other
          end
        when :other
          words << current_word unless current_word.empty?
          if start_of_tag?(char)
            current_word = +'<'
            mode = :tag
          else
            current_word = char
            mode = :wordchar if wordchar?(char)
          end
        else
          raise "Unknown mode #{mode.inspect}"
        end

        position += 1
      end

      words << current_word unless current_word.empty?
      words
    end

    private

    def extract_special_entities(string)
      entities = []

      # Extract HTML entities (these have priority)
      string.scan(HTML_ENTITY_REGEXP) do |match|
        full_match = "&#{match[0]};"
        start_pos = Regexp.last_match.offset(0)[0]
        end_pos = start_pos + full_match.length
        entities << [full_match, start_pos, end_pos]
      end

      # Extract URLs
      string.scan(URL_REGEXP) do
        full_match = Regexp.last_match[0]
        start_pos = Regexp.last_match.offset(0)[0]
        end_pos = start_pos + full_match.length
        entities << [full_match, start_pos, end_pos]
      end

      # Extract emails
      string.scan(EMAIL_REGEXP) do
        full_match = Regexp.last_match[0]
        start_pos = Regexp.last_match.offset(0)[0]
        end_pos = start_pos + full_match.length
        entities << [full_match, start_pos, end_pos]
      end

      # Extract phone numbers
      # string.scan(PHONE_REGEXP) do
      #   full_match = Regexp.last_match[0]
      #   start_pos = Regexp.last_match.offset(0)[0]
      #   end_pos = start_pos + full_match.length
      #   entities << [full_match, start_pos, end_pos]
      # end

      # Sort by start position to ensure we process them in order
      entities.sort_by { |_, start_pos, _| start_pos }
    end

    def end_of_tag?(char)
      char == '>'
    end

    def start_of_tag?(char)
      char == '<'
    end

    def wordchar?(char)
      char.match?(WORDCHAR_REGEXP)
    end
  end
end
