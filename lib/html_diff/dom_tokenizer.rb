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

# frozen_string_literal: true

require 'nokogiri'

module HTMLDiff
  # Tokenizes HTML while preserving DOM structure
  class DomTokenizer
    class ParseError < StandardError; end

    def initialize(options = {})
      @preserve_whitespace = options[:preserve_whitespace] || false
    end

    # Tokenizes HTML in a DOM-aware way
    #
    # @param html [String] The HTML string to tokenize
    # @return [Array] Nested array structure representing the DOM
    def self.tokenize(html, options = {})
      new(options).tokenize(html)
    end

    def tokenize(html)
      return [] if !html || html.empty?

      begin
        html = html.encode('UTF-8', invalid: :replace, undef: :replace, replace: ' ')

        # Simple text case
        if !html.include?('<') && !html.include?('>')
          return [html]
        end

        # Parse the HTML
        doc = Nokogiri::HTML(html, nil, 'UTF-8')

        result = []

        # Add DOCTYPE if present (and if in the original HTML)
        if doc.internal_subset && html.include?('<!DOCTYPE')
          result << ['<!DOCTYPE', ' ', 'html>']
        end

        # Check for malformed HTML
        check_for_malformed_html(html)

        # Special case for a single paragaph of plain text
        if doc.at_css('body') &&
          doc.at_css('body').children.size == 1 &&
          doc.at_css('body').children.first.text? &&
          !html.match(/<[^>]+>/)
          return [doc.at_css('body').content]
        end

        # Process html element or direct children depending on the input
        if html.strip.start_with?('<html') || html.include?('<!DOCTYPE')
          html_node = doc.at_css('html')
          result << process_node(html_node) if html_node
        else
          # Process all direct children
          nodes = doc.css('body > *')

          # If no nodes found in body, try document level
          nodes = doc.children.reject { |n| n.name == 'html' } if nodes.empty?

          nodes.each do |node|
            token = process_node(node)
            result << token if token
          end
        end

        result
      rescue Nokogiri::XML::SyntaxError => e
        raise ParseError, "Error parsing HTML: #{e.message}"
      rescue => e
        raise ParseError, "Error processing HTML: #{e.message}"
      end
    end

    private

    def check_for_malformed_html(html)
      # Simple check for unbalanced tags
      opening_tags = html.scan(/<([a-zA-Z0-9]+)(?:\s+[^>]*)?(?!\/)>/i).flatten
      closing_tags = html.scan(/<\/([a-zA-Z0-9]+)>/i).flatten

      # Identify self-closing tags
      void_elements = ['img', 'br', 'hr', 'meta', 'input', 'link', 'area', 'base', 'col', 'embed',
                       'param', 'source', 'track', 'wbr']

      # Count tags that need matching
      tag_counts = Hash.new(0)

      opening_tags.each do |tag|
        tag_counts[tag.downcase] += 1 unless void_elements.include?(tag.downcase)
      end

      closing_tags.each do |tag|
        tag_counts[tag.downcase] -= 1
      end

      # Check for any unbalanced tags
      tag_counts.each do |tag, count|
        if count != 0
          raise ParseError, "Unbalanced tags: #{tag}"
        end
      end
    end

    def process_node(node)
      case node.type
      when Nokogiri::XML::Node::TEXT_NODE
        process_text_node(node)
      when Nokogiri::XML::Node::ELEMENT_NODE
        process_element_node(node)
      when Nokogiri::XML::Node::COMMENT_NODE
        nil # Ignore comments
      when Nokogiri::XML::Node::CDATA_SECTION_NODE
        node.content # Return CDATA content as is
      else
        nil
      end
    end

    def process_text_node(node)
      content = node.content

      # Skip empty text nodes unless preserving whitespace
      return nil if !@preserve_whitespace && content.strip.empty?

      # Decode HTML entities
      content = decode_html_entities(content)

      content
    end

    def decode_html_entities(text)
      text.gsub(/&lt;/, '<')
          .gsub(/&gt;/, '>')
          .gsub(/&amp;/, '&')
          .gsub(/&quot;/, '"')
          .gsub(/&apos;/, "'")
          .gsub(/&nbsp;/, ' ')
          .gsub(/&#(\d+);/) { [$1.to_i].pack('U') }
        .gsub(/&#x([0-9a-fA-F]+);/) { [$1.to_i(16)].pack('U') }
    end

    def process_element_node(node)
      # Extract attributes
      attrs = {}
      node.attributes.each do |name, attr|
        attrs[name] = attr.value
      end

      # Handle self-closing tags
      if is_self_closing?(node)
        return [node.name, attrs, nil]
      end

      # Process children
      children = []
      has_text = false
      has_elements = false

      node.children.each do |child|
        if child.text? && (!child.content.strip.empty? || @preserve_whitespace)
          has_text = true
        elsif child.element?
          has_elements = true
        end

        child_token = process_node(child)
        children << child_token if child_token
      end

      # Return appropriate structure based on content type
      if children.empty?
        [node.name, attrs, []]
      elsif has_text && has_elements
        # Mixed content
        [node.name, attrs, children]
      elsif children.size == 1 && children.first.is_a?(String)
        # Single text node child
        [node.name, attrs, children.first]
      else
        # Multiple children or single element child
        [node.name, attrs, children]
      end
    end

    def is_self_closing?(node)
      ['img', 'br', 'hr', 'meta', 'input', 'link', 'area', 'base', 'col', 'embed',
       'param', 'source', 'track', 'wbr'].include?(node.name.downcase) && node.children.empty?
    end
  end
end
