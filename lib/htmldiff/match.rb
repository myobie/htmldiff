# frozen_string_literal: true

module HTMLDiff
  Match = Struct.new(:start_in_old, :start_in_new, :size)
  class Match
    def end_in_old
      start_in_old + size
    end

    def end_in_new
      start_in_new + size
    end
  end
end
