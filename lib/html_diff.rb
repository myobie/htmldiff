# frozen_string_literal: true

require 'html_diff/tokenizer'
require 'html_diff/dom_tokenizer'
require 'html_diff/differ'
require 'html_diff/tree_differ'
require 'html_diff/html_formatter'
require 'html_diff/version'
require 'html_diff/diff_builder' # @deprecated

# Provides functionality for generating HTML-formatted diffs
# between two text strings.
module HTMLDiff
  extend self

  # Generate an HTML diff between two strings
  #
  # @param old_string [String] The original string
  # @param new_string [String] The new string
  # @option :html_format [Hash] An optional hash of options to pass to the formatter.
  # @option :preserve_dom [Boolean] Whether to preserve DOM structure in the diff
  #   output, ensuring valid HTML when diffing content with block elements.
  # @option :merge_threshold [Object] Maximum string length of unchanged tokens
  #   to merge into neighboring changes. Value 0 merges only whitespace.
  #   Negative values disable merging. Default value is 5.
  # @option :tokenizer [Object] An optional object which responds to `tokenize`,
  #   which is used break the input strings into an Array of LCS-diffable tokens.
  # @option :formatter [Object] An optional object which responds to `format`,
  #   which renders the LCS-diff output.
  # @return [String] Diff of the two strings with additions and deletions marked.
  def diff(old_string,
           new_string,
           html_format: nil,
           preserve_dom: false,
           merge_threshold: nil,
           tokenizer: nil,
           formatter: nil)

    tokenizer ||= preserve_dom ? DomTokenizer : Tokenizer
    old_tokens = tokenizer.tokenize(old_string)
    new_tokens = tokenizer.tokenize(new_string)

    changes = Differ.diff(old_tokens, new_tokens, merge_threshold: merge_threshold)

    if formatter
      formatter.format(changes)
    else
      HtmlFormatter.format(changes, **(html_format || {})) # double-splat nil only supported in Ruby 3.3+
    end
  end
end
