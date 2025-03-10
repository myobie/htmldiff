# frozen_string_literal: true

require 'htmldiff/tokenizer'
require 'htmldiff/match'
require 'htmldiff/operation'
require 'htmldiff/operation_generator'
require 'htmldiff/output_formatter'

module HTMLDiff
  extend self

  # Generate an HTML diff between two strings
  #
  # @param old_string [String] the original string
  # @param new_string [String] the new string
  # @option formatter [Object] an optional object which responds to `format`
  # @return [String] HTML diff of the two strings with additions and deletions marked
  def diff(old_string, new_string, formatter: nil)
    formatter ||= OutputFormatter
    old_tokens = Tokenizer.tokenize(old_string)
    new_tokens = Tokenizer.tokenize(new_string)
    operations = OperationGenerator.generate_operations(old_tokens, new_tokens)
    formatter.format(operations, old_tokens, new_tokens)
  end
end
