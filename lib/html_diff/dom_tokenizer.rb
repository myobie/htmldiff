# frozen_string_literal: true

require 'nokogiri'

module HTMLDiff
  # Tokenizes HTML while preserving DOM structure
  module DomTokenizer
    extend self

    # Tokenizes HTML in a DOM-aware way
    #
    # @param html [String] The HTML string to tokenize
    # @return [Array] Nested array structure representing the DOM
    def tokenize(html)
      return [] if !html || html.empty?

      html = html.encode('UTF-8', invalid: :replace, undef: :replace, replace: ' ')

      # Parse the HTML
      doc = Nokogiri::HTML(html)

      result = []

      # Add DOCTYPE if present
      if doc.internal_subset
        result << ['<!DOCTYPE', ' ', 'html>']
      end

      # Process the root html element
      html_element = doc.at_css('html')
      if html_element
        result << tokenize_element(html_element)
      end

      result
    end

    private

    # Tokenize an element into [name, attributes_hash, children_array]
    def tokenize_element(element)
      # Extract attributes
      attrs = {}
      element.attributes.each do |name, attr|
        attrs[name] = attr.value
      end

      # Process children
      children = []
      element.children.each do |child|
        if child.text?
          # Tokenize text
          tokens = tokenize_text(child.content)
          children << tokens unless tokens.empty?
        elsif child.element?
          # Recursively tokenize element
          children << tokenize_element(child)
        end
      end

      [element.name, attrs, children]
    end

    # Tokenize text content
    def tokenize_text(text)
      return [] if text.strip.empty?

      # TODO: This junk needs to be fixed.
      result = []
      words = text.split(/(\s+|\b|(?=[.,;:!?]))/)
                  .reject(&:empty?)
                  .map { |w| w =~ /\A\s+\z/ ? ' ' : w }

      words.each do |word|
        result << word
      end

      Tokenizer.tokenize(result.join(''))
    end
  end
end
