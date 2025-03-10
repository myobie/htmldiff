# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff::Operation do
  describe "initialization" do
    it "creates a valid operation with action and positions" do
      operation = HTMLDiff::Operation.new(:equal, 1, 4, 2, 5)
      expect(operation.action).to eq(:equal)
      expect(operation.start_in_old).to eq(1)
      expect(operation.end_in_old).to eq(4)
      expect(operation.start_in_new).to eq(2)
      expect(operation.end_in_new).to eq(5)
    end

    it "supports insert operation" do
      operation = HTMLDiff::Operation.new(:insert, 5, 5, 7, 9)
      expect(operation.action).to eq(:insert)
      expect(operation.start_in_old).to eq(5)
      expect(operation.end_in_old).to eq(5)
      expect(operation.start_in_new).to eq(7)
      expect(operation.end_in_new).to eq(9)
    end

    it "supports delete operation" do
      operation = HTMLDiff::Operation.new(:delete, 3, 8, 10, 10)
      expect(operation.action).to eq(:delete)
      expect(operation.start_in_old).to eq(3)
      expect(operation.end_in_old).to eq(8)
      expect(operation.start_in_new).to eq(10)
      expect(operation.end_in_new).to eq(10)
    end

    it "supports replace operation" do
      operation = HTMLDiff::Operation.new(:replace, 10, 15, 12, 18)
      expect(operation.action).to eq(:replace)
      expect(operation.start_in_old).to eq(10)
      expect(operation.end_in_old).to eq(15)
      expect(operation.start_in_new).to eq(12)
      expect(operation.end_in_new).to eq(18)
    end
  end
end
