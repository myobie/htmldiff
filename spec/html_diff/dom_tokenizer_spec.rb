# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff::DomTokenizer do
  describe '.tokenize' do
    subject(:tokenizer) { described_class }

    it 'returns an empty array for empty string' do
      expect(tokenizer.tokenize('')).to eq([])
    end

    it 'parses a simple text node' do
      expect(tokenizer.tokenize('Hello World')).to eq(['Hello World'])
    end

    it 'parses a single tag without attributes' do
      html = '<p>Paragraph</p>'
      expected = [
        ['p', {}, 'Paragraph']
      ]
      expect(tokenizer.tokenize(html)).to eq(expected)
    end

    it 'parses a single tag with attributes' do
      html = '<p class="intro" id="first">Paragraph</p>'
      expected = [
        ['p', { 'class' => 'intro', 'id' => 'first' }, ['Paragraph']]
      ]
      expect(tokenizer.tokenize(html)).to eq(expected)
    end

    it 'parses nested tags' do
      html = '<div><p>Paragraph</p></div>'
      expected = [
        ['div', {}, [
          ['p', {}, ['Paragraph']]
        ]]
      ]
      expect(tokenizer.tokenize(html)).to eq(expected)
    end

    it 'parses sibling tags' do
      html = '<div><h1>Title</h1><p>Paragraph</p></div>'
      expected = [
        ['div', {}, [
          ['h1', {}, ['Title']],
          ['p', {}, ['Paragraph']]
        ]]
      ]
      expect(tokenizer.tokenize(html)).to eq(expected)
    end

    it 'parses complex nested structure' do
      html = '<section id="content"><header><h1>Title</h1></header><article><p>Text</p><ul><li>Item 1</li><li>Item 2</li></ul></article></section>'
      expected = [
        ['section', { 'id' => 'content' }, [
          ['header', {}, [
            ['h1', {}, ['Title']]
          ]],
          ['article', {}, [
            ['p', {}, ['Text']],
            ['ul', {}, [
              ['li', {}, ['Item 1']],
              ['li', {}, ['Item 2']]
            ]]
          ]]
        ]]
      ]
      expect(tokenizer.tokenize(html)).to eq(expected)
    end

    it 'handles self-closing tags' do
      html = '<div><img src="image.jpg" alt="Image"/><p>Description</p></div>'
      expected = [
        ['div', {}, [
          ['img', { 'src' => 'image.jpg', 'alt' => 'Image' }, nil],
          ['p', {}, ['Description']]
        ]]
      ]
      expect(tokenizer.tokenize(html)).to eq(expected)
    end

    it 'handles tags with mixed content' do
      html = '<p>This is <strong>important</strong> text</p>'
      expected = [
        ['p', {}, [
          ['This is '],
          ['strong', {}, ['important']],
          [' ', 'text']
        ]]
      ]
      expect(tokenizer.tokenize(html)).to eq(expected)
    end

    it 'handles malformed HTML by raising an error' do
      html = '<div><p>Unclosed paragraph tag</div>'
      expect { tokenizer.tokenize(html) }.to raise_error(described_class::ParseError)
    end

    it 'preserves whitespace when specified' do
      tokenizer = described_class.tokenize(preserve_whitespace: true)
      html = '<div>\n  <p>  Spaced  text  </p>\n</div>'
      expected = [
        ['div', {}, [
          ["\n", " ", " "],
          ['p', {}, ' ', ' ', 'Spaced', ' ', ' ', 'text', ' ', ' '],
          ["\n"]
        ]]
      ]
      expect(tokenizer.tokenize(html)).to eq(expected)
    end

    it 'ignores comments' do
      html = '<div><!-- This is a comment --><p>Text</p></div>'
      expected = [
        ['div', {}, [
          ['p', {}, ['Text']]
        ]]
      ]
      expect(tokenizer.tokenize(html)).to eq(expected)
    end

    it 'handles CDATA sections' do
      html = '<div><![CDATA[<strong>This should not be parsed</strong>]]></div>'
      expected = [
        ['div', {}, '<strong>This should not be parsed</strong>']
      ]
      expect(tokenizer.tokenize(html)).to eq(expected)
    end

    it 'handles HTML entities' do
      html = '<p>&lt;div&gt; is a block element &amp; &quot;p&quot; is another</p>'
      expected = [
        ['p', {}, ['<div>', ' ', 'is', ' ', 'a', ' ', 'block', ' ', 'element', ' ', '&', ' ', '"', 'p', '"', ' ', 'is', ' ', 'another']]
      ]
      expect(tokenizer.tokenize(html)).to eq(expected)
    end

    context 'complex case' do
      let(:html) do
        <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>My Sample Webpage</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    margin: 0;
                    padding: 20px;
                }
                .container {
                    max-width: 800px;
                    margin: 0 auto;
                }
                header {
                    background-color: #f5f5f5;
                    padding: 15px;
                    border-radius: 5px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <header>
                    <h1>Welcome to My Website</h1>
                    <p>This is a sample nested HTML document.</p>
                </header>
                <main>
                    <section>
                        <h2>About Us</h2>
                        <p>We are a <em>fictional</em> company that specializes in <strong>web development</strong>.</p>
                        <ul>
                            <li>HTML coding</li>
                            <li>CSS styling</li>
                            <li>JavaScript programming</li>
                        </ul>
                    </section>
                    <section>
                        <h2>Contact Information</h2>
                        <p>You can reach us at:</p>
                        <address>
                            <a href="mailto:info@example.com">info@example.com</a><br>
                            <a href="tel:+15551234567">+1 (555) 123-4567</a>
                        </address>
                    </section>
                </main>
                <footer>
                    <p>&copy; 2025 My Sample Website. All rights reserved.</p>
                </footer>
            </div>
        </body>
        </html>
      HTML
      end

      let(:expected) do
        [
          ['<!DOCTYPE', ' ', 'html>'],
          ['html', {'lang' => 'en'}, [
            ['head', {}, [
              ['meta', {'charset' => 'UTF-8'}, []],
              ['meta', {'name' => 'viewport', 'content' => 'width=device-width, initial-scale=1.0'}, []],
              ['title', {}, [['My', ' ', 'Sample', ' ', 'Webpage']]],
              ['style', {}, [['body', ' ', '{', ' ', 'font-family:', ' ', 'Arial,', ' ', 'sans-serif;', ' ', 'margin:', ' ', '0;', ' ', 'padding:', ' ', '20px;', ' ', '}', ' ',
                              '.container', ' ', '{', ' ', 'max-width:', ' ', '800px;', ' ', 'margin:', ' ', '0', ' ', 'auto;', ' ', '}', ' ',
                              'header', ' ', '{', ' ', 'background-color:', ' ', '#f5f5f5;', ' ', 'padding:', ' ', '15px;', ' ', 'border-radius:', ' ', '5px;', ' ', '}']]]
            ]],
            ['body', {}, [
              ['div', {'class' => 'container'}, [
                ['header', {}, [
                  ['h1', {}, [['Welcome', ' ', 'to', ' ', 'My', ' ', 'Website']]],
                  ['p', {}, [['This', ' ', 'is', ' ', 'a', ' ', 'sample', ' ', 'nested', ' ', 'HTML', ' ', 'document', '.']]]
                ]],
                ['main', {}, [
                  ['section', {}, [
                    ['h2', {}, [['About', ' ', 'Us']]],
                    ['p', {}, [['We', ' ', 'are', ' ', 'a', ' '], ['em', {}, [['fictional']]], [' ', 'company', ' ', 'that', ' ', 'specializes', ' ', 'in', ' '], ['strong', {}, [['web', ' ', 'development']], ['.']]]],
                    ['ul', {}, [
                      ['li', {}, [['HTML', ' ', 'coding']]],
                      ['li', {}, [['CSS', ' ', 'styling']]],
                      ['li', {}, [['JavaScript', ' ', 'programming']]]
                    ]]
                  ]],
                  ['section', {}, [
                    ['h2', {}, [['Contact', ' ', 'Information']]],
                    ['p', {}, [['You', ' ', 'can', ' ', 'reach', ' ', 'us', ' ', 'at', ':']]],
                    ['address', {}, [
                      ['a', {'href' => 'mailto:info@example.com'}, [['info@example.com']]],
                      ['br', {}, []],
                      ['a', {'href' => 'tel:+15551234567'}, [["+1", " ", "(", "555", ")", " ", "123-4567"]]]
                    ]]
                  ]]
                ]],
                ['footer', {}, [
                  ['p', {}, [['©', ' ', '2025', ' ', 'My', ' ', 'Sample', ' ', 'Website', '.', ' ', 'All', ' ', 'rights', ' ', 'reserved', '.']]]
                ]]
              ]]
            ]]
          ]]
        ]
      end

      it 'tokenizes HTML correctly' do
        tokens = described_class.tokenize(html)
        expect(tokens).to eq(expected)
      end
    end
  end
end
