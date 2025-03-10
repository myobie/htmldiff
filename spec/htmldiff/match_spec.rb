# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff::Match do
  describe "initialization" do
    it "creates a valid match with start positions and size" do
      match = HTMLDiff::Match.new(5, 10, 3)
      expect(match.start_in_old).to eq(5)
      expect(match.start_in_new).to eq(10)
      expect(match.size).to eq(3)
    end
  end

  describe "#end_in_old" do
    it "calculates the end position in old text" do
      match = HTMLDiff::Match.new(5, 10, 3)
      expect(match.end_in_old).to eq(8) # 5 + 3
    end

    it "handles zero size matches" do
      match = HTMLDiff::Match.new(5, 10, 0)
      expect(match.end_in_old).to eq(5)
    end
  end

  describe "#end_in_new" do
    it "calculates the end position in new text" do
      match = HTMLDiff::Match.new(5, 10, 3)
      expect(match.end_in_new).to eq(13) # 10 + 3
    end

    it "handles zero size matches" do
      match = HTMLDiff::Match.new(5, 10, 0)
      expect(match.end_in_new).to eq(10)
    end
  end
end
