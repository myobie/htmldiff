# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff::OperationGenerator do
  describe ".generate_operations" do
    context "with empty inputs" do
      it "returns empty operations for empty tokens" do
        operations = described_class.generate_operations([], [])
        expect(operations).to be_empty
      end
    end

    context "with insertion operations" do
      it "generates an insert operation when adding new content" do
        operations = described_class.generate_operations([], ["a", "b", "c"])
        
        expect(operations.size).to eq(1)
        expect(operations[0].action).to eq(:insert)
        expect(operations[0].start_in_old).to eq(0)
        expect(operations[0].end_in_old).to eq(0)
        expect(operations[0].start_in_new).to eq(0)
        expect(operations[0].end_in_new).to eq(3)
      end

      it "generates an insert operation in the middle of content" do
        operations = described_class.generate_operations(
          ["a", "d"],
          ["a", "b", "c", "d"]
        )
        
        expect(operations.size).to eq(3)
        
        # First equal operation for "a"
        expect(operations[0].action).to eq(:equal)
        expect(operations[0].start_in_old).to eq(0)
        expect(operations[0].end_in_old).to eq(1)
        
        # Insert operation for "b", "c"
        expect(operations[1].action).to eq(:insert)
        expect(operations[1].start_in_old).to eq(1)
        expect(operations[1].end_in_old).to eq(1)
        expect(operations[1].start_in_new).to eq(1)
        expect(operations[1].end_in_new).to eq(3)
        
        # Second equal operation for "d"
        expect(operations[2].action).to eq(:equal)
      end

      it 'preserves leading whitespace' do
        old_words = ["Hello", " ", "world"]
        new_words = ["Hello", " ", "beautiful", " ", "world"]

        operations = described_class.generate_operations(old_words, new_words)

        expected_operations = [
          HTMLDiff::Operation.new(:equal, 0, 2, 0, 2),  # Equal: "Hello "
          HTMLDiff::Operation.new(:insert, 2, 2, 2, 4), # Insert: "beautiful "
          HTMLDiff::Operation.new(:equal, 2, 3, 4, 5)   # Equal: "world"
        ]

        expect(operations).to eq(expected_operations)
      end
    end

    context "with deletion operations" do
      it "generates a delete operation when removing content" do
        operations = described_class.generate_operations(
          ["a", "b", "c"],
          []
        )
        
        expect(operations.size).to eq(1)
        expect(operations[0].action).to eq(:delete)
        expect(operations[0].start_in_old).to eq(0)
        expect(operations[0].end_in_old).to eq(3)
        expect(operations[0].start_in_new).to eq(0)
        expect(operations[0].end_in_new).to eq(0)
      end

      it "generates a delete operation in the middle of content" do
        operations = described_class.generate_operations(
          ["a", "b", "c", "d"],
          ["a", "d"]
        )
        
        expect(operations.size).to eq(3)
        
        # First equal operation for "a"
        expect(operations[0].action).to eq(:equal)
        expect(operations[0].start_in_old).to eq(0)
        expect(operations[0].end_in_old).to eq(1)
        
        # Delete operation for "b", "c"
        expect(operations[1].action).to eq(:delete)
        expect(operations[1].start_in_old).to eq(1)
        expect(operations[1].end_in_old).to eq(3)
        expect(operations[1].start_in_new).to eq(1)
        expect(operations[1].end_in_new).to eq(1)
        
        # Second equal operation for "d"
        expect(operations[2].action).to eq(:equal)
      end

      it 'preserves leading whitespace' do
        old_words = ["Hello", " ", "beautiful", " ", "world"]
        new_words = ["Hello", " ", "world"]

        operations = described_class.generate_operations(old_words, new_words)

        expected_operations = [
          HTMLDiff::Operation.new(:equal, 0, 2, 0, 2),  # Equal: "Hello "
          HTMLDiff::Operation.new(:delete, 2, 4, 2, 2), # Delete: "beautiful "
          HTMLDiff::Operation.new(:equal, 4, 5, 2, 3)   # Equal: "world"
        ]

        expect(operations).to eq(expected_operations)
      end
    end

    context "with equal operations" do
      it "generates an equal operation for identical content" do
        operations = described_class.generate_operations(
          ["a", "b", "c"],
          ["a", "b", "c"]
        )
        
        expect(operations.size).to eq(1)
        expect(operations[0].action).to eq(:equal)
        expect(operations[0].start_in_old).to eq(0)
        expect(operations[0].end_in_old).to eq(3)
        expect(operations[0].start_in_new).to eq(0)
        expect(operations[0].end_in_new).to eq(3)
      end
    end

    context "with replace operations" do
      it "generates a replace operation for changed content" do
        operations = described_class.generate_operations(
          ["a", "b", "c"],
          ["x", "y", "z"]
        )
        
        expect(operations.size).to eq(1)
        expect(operations[0].action).to eq(:replace)
        expect(operations[0].start_in_old).to eq(0)
        expect(operations[0].end_in_old).to eq(3)
        expect(operations[0].start_in_new).to eq(0)
        expect(operations[0].end_in_new).to eq(3)
      end

      it "generates a replace operation for partially changed content" do
        operations = described_class.generate_operations(
          ["a", "b", "c"],
          ["a", "x", "c"]
        )
        
        expect(operations.size).to eq(3)
        
        # Equal for "a"
        expect(operations[0].action).to eq(:equal)
        expect(operations[0].start_in_old).to eq(0)
        expect(operations[0].end_in_old).to eq(1)
        
        # Replace "b" with "x"
        expect(operations[1].action).to eq(:replace)
        expect(operations[1].start_in_old).to eq(1)
        expect(operations[1].end_in_old).to eq(2)
        expect(operations[1].start_in_new).to eq(1)
        expect(operations[1].end_in_new).to eq(2)
        
        # Equal for "c"
        expect(operations[2].action).to eq(:equal)
        expect(operations[2].start_in_old).to eq(2)
        expect(operations[2].end_in_old).to eq(3)
      end

      it 'preserves leading whitespace' do
        old_words = ["Hello", " ", "world", "!"]
        new_words = ["Hello", " ", "everyone", "!"]

        operations = described_class.generate_operations(old_words, new_words)

        expected_operations = [
          HTMLDiff::Operation.new(:equal, 0, 2, 0, 2),   # Equal: "Hello "
          HTMLDiff::Operation.new(:replace, 2, 3, 2, 3), # Replace: "world" with "everyone"
          HTMLDiff::Operation.new(:equal, 3, 4, 3, 4)    # Equal: "!"
        ]

        expect(operations).to eq(expected_operations)
      end
    end

    context "with complex scenarios" do
      it "handles mixed operations" do
        operations = described_class.generate_operations(
          ["a", "b", "c", "d", "e"],
          ["a", "x", "c", "y", "e"]
        )
        
        expect(operations.size).to eq(5)
        
        # Equal "a"
        expect(operations[0].action).to eq(:equal)
        
        # Replace "b" with "x"
        expect(operations[1].action).to eq(:replace)
        
        # Equal "c"
        expect(operations[2].action).to eq(:equal)
        
        # Replace "d" with "y"
        expect(operations[3].action).to eq(:replace)
        
        # Equal "e"
        expect(operations[4].action).to eq(:equal)
      end

      it "finds matches that span multiple tokens" do
        operations = described_class.generate_operations(
          ["a", "b", "c", "d", "e", "f"],
          ["x", "y", "c", "d", "z"]
        )
        
        # There should be a match for "c", "d"
        expect(operations.any? { |op| 
          op.action == :equal && 
          op.start_in_old == 2 && 
          op.end_in_old == 4 && 
          op.start_in_new == 2 && 
          op.end_in_new == 4 
        }).to be true
      end

      it "handles completely different content" do
        operations = described_class.generate_operations(
          ["hello", "world"],
          ["goodbye", "everyone"]
        )
        
        expect(operations.size).to eq(1)
        expect(operations[0].action).to eq(:replace)
      end

      it "handles complex interleaved changes" do
        old_tokens = ["a", "b", "c", "d", "e", "f", "g", "h"]
        new_tokens = ["a", "c", "e", "g", "i", "j", "k"]
        
        operations = described_class.generate_operations(old_tokens, new_tokens)
        
        # Validate that operations cover all tokens
        old_covered = operations.sum { |op| op.end_in_old - op.start_in_old }
        new_covered = operations.sum { |op| op.end_in_new - op.start_in_new }
        
        expect(old_covered).to eq(old_tokens.size)
        expect(new_covered).to eq(new_tokens.size)
        
        # Check that the operations are valid
        operations.each do |op|
          expect([:equal, :insert, :delete, :replace]).to include(op.action)
          expect(op.start_in_old).to be >= 0
          expect(op.end_in_old).to be <= old_tokens.size
          expect(op.start_in_new).to be >= 0
          expect(op.end_in_new).to be <= new_tokens.size
        end
      end

      it "handles multiple languages" do
        old_tokens = ["Hello", " ", "नमस्ते", " ", "こ", "ん", "に", "ち", "は"]
        new_tokens = ["Hello", " ", "नमस्ते", " ", "मित्र", " ", "こ", "ん", "に", "ち", "は", " ", "世", "界"]

        operations = described_class.generate_operations(old_tokens, new_tokens)

        expected_operations = [
          HTMLDiff::Operation.new(:equal, 0, 4, 0, 4),   # Equal: "Hello " + "नमस्ते "
          HTMLDiff::Operation.new(:insert, 4, 4, 4, 6),  # Insert: "मित्र "
          HTMLDiff::Operation.new(:equal, 4, 9, 6, 11),  # Equal: "こんにちは"
          HTMLDiff::Operation.new(:insert, 9, 9, 11, 14) # Insert: " 世界"
        ]

        expect(operations).to eq(expected_operations)
      end
    end
  end
end
