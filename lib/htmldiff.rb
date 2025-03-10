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
  # @param a [String] the original string
  # @param b [String] the new string
  # @option formatter [Object] an optional object which responds to `format`
  # @return [String] HTML diff of the two strings with additions and deletions marked
  def diff(a, b, formatter: nil)
    formatter ||= OutputFormatter
    a = Tokenizer.tokenize(a)
    b = Tokenizer.tokenize(b)
    operations = OperationGenerator.generate_operations(a, b)
    formatter.format(operations, a, b)
  end
end
