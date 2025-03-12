# frozen_string_literal: true

require 'strscan'

module HTMLDiff
  # Splits a string into tokens for diff comparison.
  module Tokenizer
    extend self

    # Regular expressions for special token types (prioritized)
    HTML_ENTITY_REGEXP = /\A&([a-zA-Z0-9]+|#[0-9]{1,6}|#x[0-9a-fA-F]{1,6});/.freeze
    HTML_TAG_REGEXP = /\A<[^>]+>/.freeze
    URL_REGEXP = %r{\A(https?://|www\.)[^\s<>"']+}i.freeze
    EMAIL_REGEXP = /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/i.freeze

    # Regular expression for word tokens, using capture groups.
    # Chinese, Japanese, and Thai are intentionally omitted,
    # Since they typically do not include whitespace in text.
    WORD_REGEXP = /\A(?:
      (\d+(?:[\d,.]*\d+)?) |
      ([\p{Latin}]+) |
      ([\p{Cyrillic}]+) |
      ([\p{Greek}]+) |
      ([\p{Arabic}]+) |
      ([\p{Hebrew}]+) |
      ([\p{Devanagari}]+) |
      ([\p{Hangul}]+) |
      ([\p{Armenian}]+) |
      ([\p{Georgian}]+) |
      ([\p{Bengali}]+) |
      ([\p{Gujarati}]+) |
      ([\p{Gurmukhi}]+) |
      ([\p{Kannada}]+) |
      ([\p{Malayalam}]+) |
      ([\p{Tamil}]+) |
      ([\p{Telugu}]+) |
      ([\p{Ethiopic}]+) |
      ([\p{Khmer}]+) |
      ([\p{Lao}]+) |
      ([\p{Myanmar}]+) |
      ([\p{Sinhala}]+) |
      ([\p{Tibetan}]+) |
      ([\p{Mongolian}]+)
    )/x.freeze
    GRAPHEME_CLUSTER_REGEXP = /\A\X/.freeze

    # Tokenizes a string into an array of words and entities.
    #
    # @param string [String] The string to tokenize.
    # @return [Array<String>] The array of tokens.
    def tokenize(string)
      return [] if string.empty?

      tokens = []
      string = string.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: ' ')
      string.unicode_normalize!
      scanner = StringScanner.new(string)

      until scanner.eos?
        token = nil

        # Check for special patterns first (optimized with character peeking)
        case scanner.peek(1)
        when '<'
          token = scanner.scan(HTML_TAG_REGEXP)
        when '&'
          token = scanner.scan(HTML_ENTITY_REGEXP)
        when 'h', 'H', 'w', 'W' # Potential URL starts (http, https, www)
          token = scanner.scan(URL_REGEXP)
        end

        token ||= scanner.scan(EMAIL_REGEXP) ||
                  scanner.scan(WORD_REGEXP)

        if token
          tokens << token
          next
        end

        # Get next grapheme cluster
        tokens << scanner.scan(GRAPHEME_CLUSTER_REGEXP)
      end

      tokens
    end
  end
end
