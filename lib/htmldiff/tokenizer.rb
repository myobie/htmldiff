# frozen_string_literal: true

module HTMLDiff
  module Tokenizer
    extend self

    # The languages here use whitespace delimiters between words.
    WORDCHAR_REGEXP = /[\p{Latin}\p{Greek}\p{Cyrillic}\p{Arabic}\p{Hebrew}\p{Devanagari}\p{Hangul}\p{Armenian}\p{Georgian}\p{Ethiopic}\p{Khmer}\p{Lao}\p{Myanmar}\p{Sinhala}\p{Tamil}\p{Telugu}\p{Kannada}\p{Malayalam}\p{Tibetan}\p{Mongolian}\d]/i

    TAG_START_REGEXP = /<[^>]+>/
    URL_REGEXP = %r{(https?://|www\.)[^\s<>"']+}i
    EMAIL_REGEXP = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/i
    HTML_ENTITY_REGEXP = /&([a-zA-Z0-9]+|#[0-9]{1,6}|#x[0-9a-fA-F]{1,6});/
    # PHONE_REGEXP = /(?:\+\d{1,3}[- ]?)?\(?(?:\d{1,4})\)?[- ]?(?:\d{1,4})[- ]?(?:\d{1,4})/

    def tokenize(string)
      # Extract special entities including HTML tags (with priority for tags)
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
        when :wordchar
          if wordchar?(char)
            current_word << char
          else
            words << current_word unless current_word.empty?
            current_word = char
            mode = :other
          end
        when :other
          words << current_word unless current_word.empty?
          current_word = char
          mode = :wordchar if wordchar?(char)
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

      # Extract HTML tags first (highest priority)
      extract_tags(string, entities)

      # Then extract other special entities (but only outside of tags)
      tag_ranges = entities.select { |entity, _, _| entity.start_with?('<') && entity.end_with?('>') }
                           .map { |_, start_pos, end_pos| (start_pos...end_pos) }

      # Extract HTML entities (but only outside of tags)
      string.scan(HTML_ENTITY_REGEXP) do |match|
        full_match = "&#{match[0]};"
        start_pos = Regexp.last_match.offset(0)[0]
        end_pos = start_pos + full_match.length

        # Only add if not inside a tag
        unless inside_any_range?(start_pos, tag_ranges)
          entities << [full_match, start_pos, end_pos]
        end
      end

      # Extract URLs (but only outside of tags)
      string.scan(URL_REGEXP) do
        full_match = Regexp.last_match[0]
        start_pos = Regexp.last_match.offset(0)[0]
        end_pos = start_pos + full_match.length

        # Only add if not inside a tag
        unless inside_any_range?(start_pos, tag_ranges)
          entities << [full_match, start_pos, end_pos]
        end
      end

      # Extract emails (but only outside of tags)
      string.scan(EMAIL_REGEXP) do
        full_match = Regexp.last_match[0]
        start_pos = Regexp.last_match.offset(0)[0]
        end_pos = start_pos + full_match.length

        # Only add if not inside a tag
        unless inside_any_range?(start_pos, tag_ranges)
          entities << [full_match, start_pos, end_pos]
        end
      end

      # Sort by start position to ensure we process them in order
      entities.sort_by { |_, start_pos, _| start_pos }
    end

    def extract_tags(string, entities)
      # Parse string character by character to properly handle nested tags
      in_tag = false
      tag_start = 0

      string.chars.each_with_index do |char, i|
        if char == '<' && !in_tag
          in_tag = true
          tag_start = i
        elsif char == '>' && in_tag
          in_tag = false
          entities << [string[tag_start..i], tag_start, i + 1]
        end
      end
    end

    def inside_any_range?(position, ranges)
      ranges.any? { |range| range.cover?(position) }
    end

    def wordchar?(char)
      char.match?(WORDCHAR_REGEXP)
    end
  end
end
