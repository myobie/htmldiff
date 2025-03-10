# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff::OutputFormatter do
  describe ".format" do
    context "with empty operations" do
      it "returns empty string for empty operations" do
        result = HTMLDiff::OutputFormatter.format([], [], [])
        expect(result).to eq("")
      end
    end

    context "with equal operations" do
      it "joins unchanged text without markup" do
        operations = [
          HTMLDiff::Operation.new(:equal, 0, 3, 0, 3)
        ]
        old_words = ["Hello", " ", "world"]
        new_words = ["Hello", " ", "world"]
        
        result = HTMLDiff::OutputFormatter.format(operations, old_words, new_words)
        expect(result).to eq("Hello world")
      end
    end

    context "with insert operations" do
      it "adds ins tags with diffins class for inserted content" do
        operations = [
          HTMLDiff::Operation.new(:equal, 0, 1, 0, 1),
          HTMLDiff::Operation.new(:insert, 1, 1, 1, 4),
          HTMLDiff::Operation.new(:equal, 1, 3, 4, 5)
        ]
        old_words = ["Hello", " ", "world"]
        new_words = ["Hello", " ", "beautiful", " ", "world"]

        result = HTMLDiff::OutputFormatter.format(operations, old_words, new_words)
        expect(result).to eq('Hello<ins class="diffins"> beautiful </ins>world')
      end
    end

    context "with delete operations" do
      it "adds del tags with diffdel class for deleted content" do
        operations = [
          HTMLDiff::Operation.new(:equal, 0, 2, 0, 2),     # Equal: "Hello "
          HTMLDiff::Operation.new(:delete, 2, 4, 2, 2),    # Delete: "beautiful "
          HTMLDiff::Operation.new(:equal, 4, 5, 2, 3)      # Equal: "world"
        ]
        old_words = ["Hello", " ", "beautiful", " ", "world"]
        new_words = ["Hello", " ", "world"]

        result = HTMLDiff::OutputFormatter.format(operations, old_words, new_words)
        expect(result).to eq('Hello <del class="diffdel">beautiful </del>world')
      end
    end

    context "with replace operations" do
      it "adds del and ins tags with diffmod class for replaced content" do
        operations = [
          HTMLDiff::Operation.new(:equal, 0, 2, 0, 2),           # Equal: "Hello "
          HTMLDiff::Operation.new(:replace, 2, 3, 2, 3),         # Replace: "world" with "everyone"
          HTMLDiff::Operation.new(:equal, 3, 4, 3, 4)            # Equal: "!"
        ]
        old_words = ["Hello", " ", "world", "!"]
        new_words = ["Hello", " ", "everyone", "!"]

        result = HTMLDiff::OutputFormatter.format(operations, old_words, new_words)
        expect(result).to eq('Hello <del class="diffmod">world</del><ins class="diffmod">everyone</ins>!')
      end
    end

    context "with HTML content" do
      it "preserves HTML tags in equal operations" do
        operations = [
          HTMLDiff::Operation.new(:equal, 0, 3, 0, 3)
        ]
        old_words = ["<p>", "Hello", "</p>"]
        new_words = ["<p>", "Hello", "</p>"]

        result = HTMLDiff::OutputFormatter.format(operations, old_words, new_words)
        expect(result).to eq("<p>Hello</p>")
      end

      it "handles HTML tags in inserted content" do
        operations = [
          HTMLDiff::Operation.new(:equal, 0, 1, 0, 1),       # Equal: "Text"
          HTMLDiff::Operation.new(:insert, 1, 1, 1, 4),      # Insert: "<strong>", "bold", "</strong>"
          HTMLDiff::Operation.new(:equal, 1, 2, 4, 5)        # Equal: "</p>"
        ]
        old_words = ["Text", "</p>"]
        new_words = ["Text", "<strong>", "bold", "</strong>", "</p>"]

        result = HTMLDiff::OutputFormatter.format(operations, old_words, new_words)
        expect(result).to eq('Text<strong><ins class="diffins">bold</ins></strong></p>')
      end

      it "treats img tags specially" do
        operations = [
          HTMLDiff::Operation.new(:insert, 0, 0, 0, 1)
        ]
        old_words = []
        new_words = ['<img src="test.jpg" />']

        result = HTMLDiff::OutputFormatter.format(operations, old_words, new_words)
        expect(result).to eq('<ins class="diffins"><img src="test.jpg" /></ins>')
      end

      it "handles nested HTML structure" do
        operations = [
          HTMLDiff::Operation.new(:insert, 0, 0, 0, 5)
        ]
        old_words = []
        new_words = ["<div>", "<p>", "Hello", "</p>", "</div>"]

        result = HTMLDiff::OutputFormatter.format(operations, old_words, new_words)
        expect(result).to eq('<div><p><ins class="diffins">Hello</ins></p></div>')
      end
    end

    context "with invalid operations" do
      it "raises an error for unknown operations" do
        operations = [
          HTMLDiff::Operation.new(:unknown, 0, 1, 0, 1)
        ]
        old_words = ["Hello"]
        new_words = ["Hello"]
        
        expect {
          HTMLDiff::OutputFormatter.format(operations, old_words, new_words)
        }.to raise_error(/Unknown operation/)
      end
    end

    context "with complex operations" do
      pending "formats a complex document with multiple changes" do
        operations = [
          HTMLDiff::Operation.new(:equal, 0, 1, 0, 1),     # "<p>"
          HTMLDiff::Operation.new(:equal, 1, 2, 1, 2),     # "The"
          HTMLDiff::Operation.new(:delete, 2, 3, 2, 2),    # "old"
          HTMLDiff::Operation.new(:insert, 3, 3, 2, 3),    # "new"
          HTMLDiff::Operation.new(:equal, 3, 5, 3, 5),     # " text"
          HTMLDiff::Operation.new(:replace, 5, 7, 5, 7),   # "is here" -> "appears here"
          HTMLDiff::Operation.new(:equal, 7, 8, 7, 8)      # "</p>"
        ]

        old_words = ["<p>", "The", "old", " ", "text", "is", " here", "</p>"]
        new_words = ["<p>", "The", "new", " ", "text", "appears", " here", "</p>"]

        result = HTMLDiff::OutputFormatter.format(operations, old_words, new_words)
        expect(result).to eq(
                            '<p>The<del class="diffdel">old</del><ins class="diffins">new</ins> text' +
                              '<del class="diffmod">is</del><ins class="diffmod">appears</ins> here</p>'
                          )
      end
    end
  end
end
