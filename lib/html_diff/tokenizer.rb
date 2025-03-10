# frozen_string_literal: true

require 'strscan'

module HTMLDiff
  # Splits a string into tokens for diff comparison.
  module Tokenizer
    extend self

    # Regular expressions for different token types
    WORD_REGEXP = /\A[\p{Latin}\p{Greek}\p{Cyrillic}\p{Arabic}\p{Hebrew}\p{Devanagari}\p{Hangul}\p{Armenian}\p{Georgian}\p{Ethiopic}\p{Khmer}\p{Lao}\p{Myanmar}\p{Sinhala}\p{Tamil}\p{Telugu}\p{Kannada}\p{Malayalam}\p{Tibetan}\p{Mongolian}\d]+/i.freeze
    URL_REGEXP = %r{\A(https?://|www\.)[^\s<>()"']+}i.freeze
    EMAIL_REGEXP = /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/i.freeze
    HTML_ENTITY_REGEXP = /\A&([a-zA-Z0-9]+|#[0-9]{1,6}|#x[0-9a-fA-F]{1,6});/.freeze
    HTML_TAG_REGEXP = /\A<[^>]+>/.freeze
    UNION_REGEXP = Regexp.union(EMAIL_REGEXP, WORD_REGEXP).freeze

    # Tokenizes a string into an array of words and entities.
    #
    # @param string [String] The string to tokenize.
    # @return [Array<String>] The array of tokens.
    def tokenize(string)
      return [] if string.empty?

      tokens = []
      scanner = StringScanner.new(string)

      until scanner.eos?
        token = nil

        # Quick character check to minimize regex use
        case scanner.peek(1)
        when '<'
          token = scanner.scan(HTML_TAG_REGEXP)
        when '&'
          token = scanner.scan(HTML_ENTITY_REGEXP)
        when 'h', 'H', 'w', 'W' # Potential URL starts (http, https, www)
          token = scanner.scan(URL_REGEXP)
        end
        ((tokens << token) and next) if token

        # Other token types
        tokens << if (token = scanner.scan(UNION_REGEXP))
                    token
                  else
                    scanner.getch # Single character fallback
                  end
      end

      tokens
    end
  end
end
