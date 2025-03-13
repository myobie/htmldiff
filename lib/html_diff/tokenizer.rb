# frozen_string_literal: true

require 'strscan'

module HTMLDiff
  # Splits a string into tokens for diff comparison.
  module Tokenizer
    extend self

    # Chinese, Japanese, Thai, and other Asian languages
    # which typically do not include whitespace in text
    # are intentionally omitted.
    COMBINED_SCRIPTS = %w[
      Arabic
      Hebrew
      Devanagari
      Hangul
      Armenian
      Georgian
      Bengali
      Gujarati
      Gurmukhi
      Kannada
      Malayalam
      Tamil
      Telugu
      Ethiopic
      Sinhala
      Ethiopic
      Cherokee
      Coptic
      Syriac
    ].map { |script| "\\p{#{script}}" }.join.freeze

    # Regular expression for word tokens, using capture groups.
    # Priority order of capture groups matters.
    TOKEN_REGEXP = %r{\A(?:
      (<[^>]+>) |                                             # HTML tag
      (&(?:[a-zA-Z0-9]+|\#[0-9]{1,6}|\#x[0-9a-fA-F]{1,6});) | # HTML entity
      ((?:https?://|www\.)[^\s<>"']+) |                       # URL
      ([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}) |      # Email
      ([.+-]?\d(?:[,.-]?\d+)*) |                              # Numbers
      ([\p{Latin}]+) |
      ([\p{Cyrillic}]+) |
      ([\p{Greek}]+) |
      ([#{COMBINED_SCRIPTS}]+) |
      (\X) # Grapheme cluster
    )}ix.freeze

    # Tokenizes a string into an array of words and entities.
    #
    # @param string [String] The string to tokenize.
    # @return [Array<String>] The array of tokens.
    def tokenize(string)
      return [] if !string || string.empty?

      string = string.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: ' ')
      string.unicode_normalize!
      scanner = StringScanner.new(string)

      [].tap do |tokens|
        tokens << scanner.scan(TOKEN_REGEXP) until scanner.eos?
      end
    end
  end
end
