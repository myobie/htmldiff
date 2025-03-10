# frozen_string_literal: true

require 'htmldiff/tokenizer'
require 'htmldiff/match'
require 'htmldiff/operation'
require 'htmldiff/diff_builder'

module HTMLDiff
  extend self

  def diff(a, b)
    DiffBuilder.new(a, b).build
  end
end
