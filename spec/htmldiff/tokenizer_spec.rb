# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff::Tokenizer do
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

      it "handles non-entity ampersands" do
        tokens = HTMLDiff::Tokenizer.tokenize("A & B")
        expect(tokens).to eq(["A", " ", "&", " ", "B"])
      end

      it "handles incomplete entities" do
        tokens = HTMLDiff::Tokenizer.tokenize("&incomplete")
        expect(tokens).to eq(["&", "incomplete"])
      end
    end

    context "with mixed content" do
      it "tokenizes mixed text, tags, and entities" do
        text = '<p>Hello&nbsp;world! <strong>This</strong> is a test.</p>'
        tokens = HTMLDiff::Tokenizer.tokenize(text)
        
        expected = [
          "<p>", "Hello", "&nbsp;", "world", "!", " ", 
          "<strong>", "This", "</strong>", " ", "is", " ", 
          "a", " ", "test", ".", "</p>"
        ]
        expect(tokens).to eq(expected)
      end

      it "tokenizes multiple languages" do
        tokens = HTMLDiff::Tokenizer.tokenize("Hello Привет こんにちは")
        expect(tokens).to eq(["Hello", " ", "Привет", " ", "こ", "ん", "に", "ち", "は"])
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

    context "with email addresses" do
      it "tokenizes simple email addresses" do
        tokens = HTMLDiff::Tokenizer.tokenize("user@example.com")
        expect(tokens).to eq(["user@example.com"])
      end

      it "tokenizes email addresses with dots in username" do
        tokens = HTMLDiff::Tokenizer.tokenize("first.last@example.com")
        expect(tokens).to eq(["first.last@example.com"])
      end

      it "tokenizes email addresses with plus signs" do
        tokens = HTMLDiff::Tokenizer.tokenize("user+tag@example.com")
        expect(tokens).to eq(["user+tag@example.com"])
      end

      it "tokenizes email addresses with subdomains" do
        tokens = HTMLDiff::Tokenizer.tokenize("user@subdomain.example.com")
        expect(tokens).to eq(["user@subdomain.example.com"])
      end

      it "tokenizes email addresses with different TLDs" do
        tokens = HTMLDiff::Tokenizer.tokenize("user@example.org user@example.net")
        expect(tokens).to eq(["user@example.org", " ", "user@example.net"])
      end

      it "handles email addresses within text" do
        tokens = HTMLDiff::Tokenizer.tokenize("Contact us at support@example.com for help.")
        expect(tokens).to eq(["Contact", " ", "us", " ", "at", " ", "support@example.com", " ", "for", " ", "help", "."])
      end

      it "handles email addresses in HTML attributes" do
        tokens = HTMLDiff::Tokenizer.tokenize('<a href="mailto:contact@example.com">Email us</a>')
        expect(tokens).to eq(['<a href="mailto:contact@example.com">', "Email", " ", "us", "</a>"])
      end
    end

    context "with URLs" do
      it "tokenizes simple HTTP URLs" do
        tokens = HTMLDiff::Tokenizer.tokenize("http://example.com")
        expect(tokens).to eq(["http://example.com"])
      end

      it "tokenizes simple HTTPS URLs" do
        tokens = HTMLDiff::Tokenizer.tokenize("https://example.com")
        expect(tokens).to eq(["https://example.com"])
      end

      it "tokenizes URLs with www prefix" do
        tokens = HTMLDiff::Tokenizer.tokenize("www.example.com")
        expect(tokens).to eq(["www.example.com"])
      end

      it "tokenizes URLs with paths" do
        tokens = HTMLDiff::Tokenizer.tokenize("https://example.com/path/to/resource")
        expect(tokens).to eq(["https://example.com/path/to/resource"])
      end

      it "tokenizes URLs with query parameters" do
        tokens = HTMLDiff::Tokenizer.tokenize("https://example.com/search?q=term&page=2")
        expect(tokens).to eq(["https://example.com/search?q=term&page=2"])
      end

      it "tokenizes URLs with fragments" do
        tokens = HTMLDiff::Tokenizer.tokenize("https://example.com/page#section")
        expect(tokens).to eq(["https://example.com/page#section"])
      end

      it "handles URLs within text" do
        tokens = HTMLDiff::Tokenizer.tokenize("Visit https://example.com for more information.")
        expect(tokens).to eq(["Visit", " ", "https://example.com", " ", "for", " ", "more", " ", "information", "."])
      end

      it "handles URLs in HTML attributes" do
        tokens = HTMLDiff::Tokenizer.tokenize('<a href="https://example.com">Visit our site</a>')
        expect(tokens).to eq(['<a href="https://example.com">', "Visit", " ", "our", " ", "site", "</a>"])
      end
    end

    context "with mixed emails and URLs" do
      it "correctly tokenizes text with both emails and URLs" do
        text = "Contact us at support@example.com or visit https://example.com/support"
        tokens = HTMLDiff::Tokenizer.tokenize(text)
        expect(tokens).to eq([
                               "Contact", " ", "us", " ", "at", " ", "support@example.com", " ",
                               "or", " ", "visit", " ", "https://example.com/support"
                             ])
      end

      it "handles email addresses and URLs in HTML" do
        html = '<p>Visit <a href="https://example.com">our website</a> or email <a href="mailto:info@example.com">info@example.com</a></p>'
        tokens = HTMLDiff::Tokenizer.tokenize(html)
        expect(tokens).to eq([
                               "<p>", "Visit", " ", '<a href="https://example.com">', "our", " ", "website", "</a>", " ",
                               "or", " ", "email", " ", '<a href="mailto:info@example.com">', "info@example.com", "</a>", "</p>"
                             ])
      end

      it "handles edge cases with emails and URLs" do
        text = "User (user.name+tag@example.com) shared https://example.com/path?param=value#fragment"
        tokens = HTMLDiff::Tokenizer.tokenize(text)
        expect(tokens).to eq([
                               "User", " ", "(", "user.name+tag@example.com", ")", " ",
                               "shared", " ", "https://example.com/path?param=value#fragment"
                             ])
      end
    end
  end
end
