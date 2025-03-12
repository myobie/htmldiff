# frozen_string_literal: true

require 'html_diff/tokenizer'
require 'html_diff/differ'
require 'html_diff/html_formatter'
require 'html_diff/diff_builder' # deprecated

# Provides functionality for generating HTML-formatted diffs
# between two text strings.
module HTMLDiff
  extend self

  # Generate an HTML diff between two strings
  #
  # @param old_string [String] The original string
  # @param new_string [String] The new string
  # @option :tokenizer [Object] An optional object which responds to `tokenize`,
  #   which is used break the input strings into an Array of LCS-diffable tokens.
  # @option :format [Hash] An optional hash of options to pass to the formatter.
  # @option :formatter [Object] An optional object which responds to `format`,
  #   which renders the LCS-diff output.
  # @option :merge_threshold [Object] Maximum string length of unchanged tokens
  #   to merge into neighboring changes. Value 0 merges only whitespace.
  #   Negative values disable merging. Default value is 5.
  # @return [String] Diff of the two strings with additions and deletions marked.
  def diff(old_string, new_string, tokenizer: nil, html_format: nil, formatter: nil, merge_threshold: nil)
    tokenizer ||= Tokenizer
    old_tokens = tokenizer.tokenize(old_string)
    new_tokens = tokenizer.tokenize(new_string)

    changes = Differ.diff(old_tokens, new_tokens, merge_threshold: merge_threshold)

    Formatters::HtmlFormatter.format(changes, **html_format)
  end
end
