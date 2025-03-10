# frozen_string_literal: true

module HTMLDiff
  module Tokenizer
    extend self

    # The languages here are those that typically use space delimiters between words.
    # The characters @.- are added for email support, which could potentially be extracted to a
    # specialized function.
    WORDCHAR_REGEXP = /[\p{Latin}\p{Greek}\p{Cyrillic}\p{Arabic}\p{Hebrew}\p{Devanagari}\p{Hangul}\p{Armenian}\p{Georgian}\p{Ethiopic}\p{Khmer}\p{Lao}\p{Myanmar}\p{Sinhala}\p{Tamil}\p{Telugu}\p{Kannada}\p{Malayalam}\p{Tibetan}\p{Mongolian}\d@#.-]/i

    # TODO: Make private
    def tag?(item)
      opening_tag?(item) or closing_tag?(item)
    end

    # TODO: Make private
    def img_tag?(item)
      (item[0..4].downcase == '<img ') && (item[-2..-1].downcase == '/>')
    end

    def tokenize(string, use_brackets = false)
      mode = :wordchar
      current_word = +''
      words = []

      string.each_char do |char|
        case mode
        when :tag
          if end_of_tag?(char)
            current_word << (use_brackets ? ']' : '>')
            words << current_word unless current_word.empty?
            current_word = +''
            mode = :wordchar
          else
            current_word << char
          end
        when :html_entity
          current_word << char
          if char == ';'
            words << current_word unless current_word.empty?
            current_word = +''
            mode = :wordchar
          elsif !html_entity_char?(char)
            # This wasn't actually an HTML entity, just an ampersand followed by non-entity chars
            # Treat it as a regular word
            words << current_word unless current_word.empty?
            current_word = char
            mode = wordchar?(char) ? :wordchar : :other
          end
        when :wordchar
          if start_of_tag?(char)
            words << current_word unless current_word.empty?
            current_word = use_brackets ? +'[' : +'<'
            mode = :tag
          elsif start_of_html_entity?(char)
            words << current_word unless current_word.empty?
            current_word = char
            mode = :html_entity
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
            current_word = use_brackets ? +'[' : +'<'
            mode = :tag
          elsif start_of_html_entity?(char)
            current_word = char
            mode = :html_entity
          else
            current_word = char
            mode = :wordchar if wordchar?(char)
          end
        else
          raise "Unknown mode #{mode.inspect}"
        end
      end

      words << current_word unless current_word.empty?
      words
    end

    private

    def end_of_tag?(char)
      char == '>'
    end

    def start_of_tag?(char)
      char == '<'
    end

    def wordchar?(char)
      char.match?(WORDCHAR_REGEXP)
    end

    def html_entity_char?(char)
      char.match?(/[a-zA-Z0-9#;]/)
    end

    def start_of_html_entity?(char)
      char == '&'
    end

    def opening_tag?(item)
      item =~ %r!^\s*<[^>]+>\s*$!
    end

    def closing_tag?(item)
      item =~ %r!^\s*</[^>]+>\s*$!
    end
  end
end
