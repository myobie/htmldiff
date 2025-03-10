# frozen_string_literal: true

module HTMLDiff
  Operation = Struct.new(:action, :start_in_old, :end_in_old, :start_in_new, :end_in_new)
end
