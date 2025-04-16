# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff::TreeDiffer do
  describe '.diff' do
    context 'with simple text changes' do
      it 'marks text changes with ins and del tags' do
        old_html = '<p>This is some text</p>'
        new_html = '<p>This is modified text</p>'

        result = described_class.diff(old_html, new_html)

        expect(result).to include('<del>some</del>')
        expect(result).to include('<ins>modified</ins>')
      end
    end

    context 'with paragraph structure' do
      it 'maintains valid HTML structure' do
        old_html = '<p>Lorem ipsum dolor sit amet. foo</p>'
        new_html = <<~HTML
          <p>Lorem ipsum dolor sit amet.</p>
          <p>New paragraph</p>
          <p>And yet another new paragraph</p>
        HTML

        result = described_class.diff(old_html, new_html)

        # The diff should have valid HTML structure
        expect(result).to include('<p>Lorem ipsum dolor sit amet.<del> foo</del></p>')
        expect(result).to include('<ins><p>New paragraph</p></ins>')
        expect(result).to include('<ins><p>And yet another new paragraph</p></ins>')

        # Validate with Nokogiri to ensure it's well-formed
        expect { Nokogiri::HTML.fragment(result) }.not_to raise_error
      end
    end

    context 'with nested content' do
      it 'preserves structure in nested elements' do
        old_html = '<div><p>Old content</p></div>'
        new_html = '<div><p>New content</p></div>'

        result = described_class.diff(old_html, new_html)

        expect(result).to include('<div><p><del>Old</del><ins>New</ins> content</p></div>')
      end
    end

    context 'with lists' do
      it 'maintains valid list structure' do
        old_html = '<ul><li>Item 1</li><li>Item 2</li></ul>'
        new_html = '<ul><li>Item 1</li><li>Updated Item 2</li><li>Item 3</li></ul>'

        result = described_class.diff(old_html, new_html)

        # List structure should be preserved
        expect(result).to include('<li>Item 1</li>')
        expect(result).to include('<li><del>Item 2</del><ins>Updated Item 2</ins></li>')
        expect(result).to include('<li><ins>Item 3</ins></li>')

        # Validate with Nokogiri
        doc = Nokogiri::HTML.fragment(result)
        expect(doc.css('ul > li').size).to be >= 3
      end
    end

    context 'with tables' do
      it 'maintains valid table structure' do
        old_html = '<table><tr><td>Cell 1</td><td>Cell 2</td></tr></table>'
        new_html = '<table><tr><td>Cell 1 Updated</td><td>Cell 2</td></tr></table>'

        result = described_class.diff(old_html, new_html)

        # Table structure should be preserved
        expect(result).to include('<table>')
        expect(result).to include('<tr>')
        expect(result).to include('<td>')
        expect(result).to include('<del>Cell 1</del><ins>Cell 1 Updated</ins>')

        # Validate with Nokogiri
        doc = Nokogiri::HTML.fragment(result)
        expect(doc.css('table > tr > td').size).to eq(2)
      end
    end

    context 'with element addition' do
      it 'shows added elements' do
        old_html = '<div></div>'
        new_html = '<div><p>New paragraph</p></div>'

        result = described_class.diff(old_html, new_html)

        expect(result).to include('<div><ins><p>New paragraph</p></ins></div>')
      end
    end

    context 'with element removal' do
      it 'shows deleted elements' do
        old_html = '<div><p>Old paragraph</p></div>'
        new_html = '<div></div>'

        result = described_class.diff(old_html, new_html)

        expect(result).to include('<div><del><p>Old paragraph</p></del></div>')
      end
    end

    context 'with the problem case' do
      it 'produces valid HTML for the original problem case' do
        old_html = '<p>Lorem ipsum dolor sit amet. foo</p>'
        new_html = <<~HTML
          <p>Lorem ipsum dolor sit amet.</p>
          <p>New paragraph</p>
          <p>And yet another new paragraph</p>
        HTML

        result = described_class.diff(old_html, new_html)

        # Parse the HTML to ensure it's valid
        doc = Nokogiri::HTML.fragment(result)

        # Verify it's not broken like the original example
        expect(result).not_to include('</p><ins>')
        expect(result).not_to include('</ins></p>')

        # The content should make sense structurally
        expect(doc.css('p').size).to eq(3)
        expect(doc.css('del').size).to eq(1)
        expect(doc.css('ins').size).to eq(2)
      end
    end
  end
end
