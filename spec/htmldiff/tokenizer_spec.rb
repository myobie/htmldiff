# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff::Tokenizer do
  describe ".tag?" do
    context "with opening tags" do
      pending "identifies standard opening tags" do
        expect(HTMLDiff::Tokenizer.tag?("<div>")).to be true
        expect(HTMLDiff::Tokenizer.tag?("<p>")).to be true
      end

      pending "identifies opening tags with attributes" do
        expect(HTMLDiff::Tokenizer.tag?('<p class="test">')).to be true
        expect(HTMLDiff::Tokenizer.tag?('<a href="https://example.com">')).to be true
      end

      pending "handles whitespace in opening tags" do
        expect(HTMLDiff::Tokenizer.tag?("  <div>  ")).to be true
        expect(HTMLDiff::Tokenizer.tag?(" <p> ")).to be true
      end
    end

    context "with closing tags" do
      pending "identifies standard closing tags" do
        expect(HTMLDiff::Tokenizer.tag?("</div>")).to be true
        expect(HTMLDiff::Tokenizer.tag?("</p>")).to be true
      end

      pending "handles whitespace in closing tags" do
        expect(HTMLDiff::Tokenizer.tag?("  </div>  ")).to be true
        expect(HTMLDiff::Tokenizer.tag?(" </p> ")).to be true
      end
    end

    context "with non-tags" do
      pending "rejects plain text" do
        expect(HTMLDiff::Tokenizer.tag?("not a tag")).to be false
        expect(HTMLDiff::Tokenizer.tag?("div")).to be false
      end

      pending "rejects incomplete tags" do
        expect(HTMLDiff::Tokenizer.tag?("<div")).to be false
        expect(HTMLDiff::Tokenizer.tag?("div>")).to be false
      end

      pending "rejects HTML entities" do
        expect(HTMLDiff::Tokenizer.tag?("&nbsp;")).to be false
        expect(HTMLDiff::Tokenizer.tag?("&#169;")).to be false
      end
    end
  end

  describe ".img_tag?" do
    context "with valid img tags" do
      it "identifies self-closing img tags" do
        expect(HTMLDiff::Tokenizer.img_tag?('<img src="test.jpg" />')).to be true
        expect(HTMLDiff::Tokenizer.img_tag?('<img alt="description" />')).to be true
      end

      it "identifies img tags with multiple attributes" do
        expect(HTMLDiff::Tokenizer.img_tag?('<img src="test.jpg" alt="test" width="100" />')).to be true
      end
    end

    context "with invalid img tags" do
      it "rejects non-img tags" do
        expect(HTMLDiff::Tokenizer.img_tag?("<div>")).to be false
        expect(HTMLDiff::Tokenizer.img_tag?("<p>")).to be false
      end

      it "rejects non-self-closing img tags" do
        expect(HTMLDiff::Tokenizer.img_tag?("<img>")).to be false
        expect(HTMLDiff::Tokenizer.img_tag?("</img>")).to be false
      end

      it "rejects incomplete img tags" do
        expect(HTMLDiff::Tokenizer.img_tag?('<img src="test.jpg">')).to be false
        expect(HTMLDiff::Tokenizer.img_tag?("<img")).to be false
      end
    end
  end

  describe ".tokenize" do
    context "with plain text" do
      it "tokenizes simple words" do
        tokens = HTMLDiff::Tokenizer.tokenize("Hello world")
        expect(tokens).to eq(["Hello", " ", "world"])
      end

      it "tokenizes words with punctuation" do
        tokens = HTMLDiff::Tokenizer.tokenize("Hello, world!")
        expect(tokens).to eq(["Hello", ",", " ", "world", "!"])
      end

      it "tokenizes special characters" do
        tokens = HTMLDiff::Tokenizer.tokenize("$ % ^ &")
        expect(tokens).to eq(["$", " ", "%", " ", "^", " ", "&"])
      end

      it "tokenizes numbers as wordchars" do
        tokens = HTMLDiff::Tokenizer.tokenize("12345 67890")
        expect(tokens).to eq(["12345", " ", "67890"])
      end

      it "handles email addresses correctly" do
        tokens = HTMLDiff::Tokenizer.tokenize("Contact: user@example.com")
        expect(tokens).to eq(["Contact", ":", " ", "user@example.com"])
      end
    end

    context "with HTML content" do
      it "tokenizes HTML tags" do
        tokens = HTMLDiff::Tokenizer.tokenize("<p>Hello</p>")
        expect(tokens).to eq(["<p>", "Hello", "</p>"])
      end

      it "tokenizes nested HTML" do
        tokens = HTMLDiff::Tokenizer.tokenize("<div><p>Hello</p></div>")
        expect(tokens).to eq(["<div>", "<p>", "Hello", "</p>", "</div>"])
      end

      it "tokenizes HTML with attributes" do
        tokens = HTMLDiff::Tokenizer.tokenize('<p class="greeting">Hello</p>')
        expect(tokens).to eq(['<p class="greeting">', "Hello", "</p>"])
      end

      it "tokenizes with brackets when requested" do
        tokens = HTMLDiff::Tokenizer.tokenize("<p>Hello</p>", true)
        expect(tokens).to eq(["[p]", "Hello", "[/p]"])
      end

      it "tokenizes self-closing tags" do
        tokens = HTMLDiff::Tokenizer.tokenize('<img src="test.jpg" />')
        expect(tokens).to eq(['<img src="test.jpg" />'])
      end
    end

    context "with HTML entities" do
      it "tokenizes common HTML entities" do
        tokens = HTMLDiff::Tokenizer.tokenize("Hello&nbsp;world")
        expect(tokens).to eq(["Hello", "&nbsp;", "world"])
      end

      it "tokenizes numeric entities" do
        tokens = HTMLDiff::Tokenizer.tokenize("&#169; Copyright")
        expect(tokens).to eq(["&#169;", " ", "Copyright"])
      end

      it "tokenizes hexadecimal entities" do
        tokens = HTMLDiff::Tokenizer.tokenize("&#x1F600; Emoji")
        expect(tokens).to eq(["&#x1F600;", " ", "Emoji"])
      end

      pending "handles non-entity ampersands" do
        tokens = HTMLDiff::Tokenizer.tokenize("A & B")
        expect(tokens).to eq(["A", " ", "&", " ", "B"])
      end

      it "handles incomplete entities" do
        tokens = HTMLDiff::Tokenizer.tokenize("&incomplete")
        expect(tokens).to eq(["&incomplete"])
      end
    end

    context "with mixed content" do
      pending "tokenizes mixed text, tags, and entities" do
        text = '<p>Hello&nbsp;world! <strong>This</strong> is a test.</p>'
        tokens = HTMLDiff::Tokenizer.tokenize(text)
        
        expected = [
          "<p>", "Hello", "&nbsp;", "world", "!", " ", 
          "<strong>", "This", "</strong>", " ", "is", " ", 
          "a", " ", "test", ".", "</p>"
        ]
        expect(tokens).to eq(expected)
      end

      pending "tokenizes multiple languages" do
        # Test with multiple language scripts
        tokens = HTMLDiff::Tokenizer.tokenize("Hello Привет こんにちは")
        expect(tokens).to eq(["Hello", " ", "Привет", " ", "こんにちは"])
      end

      it "handles complex HTML with mixed content" do
        html = '<div id="content"><h1>Title</h1><p>Text with <em>emphasis</em> and <strong>importance</strong>.</p></div>'
        tokens = HTMLDiff::Tokenizer.tokenize(html)
        
        expected = [
          '<div id="content">', "<h1>", "Title", "</h1>", "<p>", "Text", " ", "with", " ", 
          "<em>", "emphasis", "</em>", " ", "and", " ", "<strong>", "importance", "</strong>", 
          ".", "</p>", "</div>"
        ]
        expect(tokens).to eq(expected)
      end
    end

    context "with edge cases" do
      it "handles empty strings" do
        tokens = HTMLDiff::Tokenizer.tokenize("")
        expect(tokens).to eq([])
      end

      pending "handles strings with only spaces" do
        tokens = HTMLDiff::Tokenizer.tokenize("   ")
        expect(tokens).to eq(["   "])
      end

      it "handles strings with only tags" do
        tokens = HTMLDiff::Tokenizer.tokenize("<div></div>")
        expect(tokens).to eq(["<div>", "</div>"])
      end

      it "handles strings with only entities" do
        tokens = HTMLDiff::Tokenizer.tokenize("&nbsp;&copy;")
        expect(tokens).to eq(["&nbsp;", "&copy;"])
      end
    end
  end
end
