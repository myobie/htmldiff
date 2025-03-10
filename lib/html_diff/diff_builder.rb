# frozen_string_literal: true

require 'diff/lcs'

# rubocop:disable Style/ClassVars
module HTMLDiff
  # Deprecated class included only for legacy compatibility.
  #
  # @deprecated Use HTMLDiff.diff instead. HTLMDiff::DiffBuilder will be removed in v2.0.0.
  class DiffBuilder
    @@warned_init = false
    @@warned_build = false

    def initialize(old_string, new_string)
      warn('HTMLDiff::DiffBuilder is deprecated and will be removed in htmldiff v2.0.0. Use HTMLDiff.diff instead.') unless @@warned_init
      @@warned_init = true
      @old_string = old_string
      @new_string = new_string
    end

    def build
      warn('HTMLDiff::DiffBuilder#build is deprecated and will be removed in htmldiff v2.0.0. Use HTMLDiff.diff instead.') unless @@warned_build
      @@warned_build = true
      HTMLDiff.diff(@old_string, @new_string)
    end
  end
end
# rubocop:enable Style/ClassVars
