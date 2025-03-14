# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff::DomTokenizer do
  describe '.tokenize' do
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
