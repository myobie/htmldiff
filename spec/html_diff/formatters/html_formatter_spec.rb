# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe HTMLDiff::Formatters::HtmlFormatter do
  let(:old_text) { 'The quick red fox jumped over the dog.' }
  let(:new_text) { 'The red fox hopped over the lazy dog.' }
  let(:example_changes) do
    [
      ['=', 'The ', 'The '],
      ['-', 'quick ', nil],
      ['=', 'red fox ', 'red fox '],
      ['!', 'jumped', 'hopped'],
      ['=', ' over the ', ' over the '],
      ['+', nil, 'lazy '],
      ['=', 'dog.', 'dog.']
    ]
  end

  describe '.format' do
    context 'with default options' do
      it 'generates the expected HTML' do
        result = described_class.format(example_changes)
        expected = 'The <del>quick </del>red fox <del>jumped</del><ins>hopped</ins> over the <ins>lazy </ins>dog.'
        expect(result).to eq(expected)
      end
    end

    context 'with equal content' do
      let(:changes) { [['=', 'This is some text', 'This is some text']] }

      it 'preserves unchanged content without markup' do
        result = described_class.format(changes)
        expect(result).to eq('This is some text')
      end
    end

    context 'with removed content' do
      let(:changes) { [['-', 'deleted text', nil]] }

      it 'wraps deleted content in del tags by default' do
        result = described_class.format(changes)
        expect(result).to eq('<del>deleted text</del>')
      end
    end

    context 'with added content' do
      let(:changes) { [['+', nil, 'added text']] }

      it 'wraps added content in ins tags by default' do
        result = described_class.format(changes)
        expect(result).to eq('<ins>added text</ins>')
      end
    end

    context 'with replaced content' do
      let(:changes) { [['!', 'old text', 'new text']] }

      it 'shows both deleted and inserted content with default tags' do
        result = described_class.format(changes)
        expect(result).to eq('<del>old text</del><ins>new text</ins>')
      end
    end

    context 'with custom tags and classes' do
      it 'applies custom tag and classes' do
        result = described_class.format(example_changes,
                                        tag: 'span',
                                        class: 'highlight',
                                        class_delete: 'removed',
                                        class_insert: 'added')

        expected = 'The <span class="removed">quick </span>red fox ' \
                   '<span class="removed">jumped</span><span class="added">hopped</span> ' \
                   'over the <span class="added">lazy </span>dog.'
        expect(result).to eq(expected)
      end
    end

    context 'with array of classes' do
      it 'joins array of classes with spaces' do
        result = described_class.format(example_changes,
                                        tag: 'span',
                                        class_delete: %w[diff diff-del bg-red-100],
                                        class_insert: %w[diff diff-ins bg-green-100])

        expected = 'The <span class="diff diff-del bg-red-100">quick </span>red fox ' \
                   '<span class="diff diff-del bg-red-100">jumped</span><span class="diff diff-ins bg-green-100">hopped</span> ' \
                   'over the <span class="diff diff-ins bg-green-100">lazy </span>dog.'
        expect(result).to eq(expected)
      end
    end

    context 'with tags for unchanged text' do
      it 'wraps unchanged text in tags when specified' do
        result = described_class.format(example_changes,
                                        tag_equal: 'span',
                                        class_equal: 'unchanged',
                                        tag_delete: 'span',
                                        class_delete: 'deleted',
                                        tag_insert: 'span',
                                        class_insert: 'inserted')

        expected = '<span class="unchanged">The </span><span class="deleted">quick </span>' \
                   '<span class="unchanged">red fox </span><span class="deleted">jumped</span>' \
                   '<span class="inserted">hopped</span><span class="unchanged"> over the </span>' \
                   '<span class="inserted">lazy </span><span class="unchanged">dog.</span>'
        expect(result).to eq(expected)
      end
    end

    context 'with special handling for replacements' do
      it 'uses custom replacement tags' do
        result = described_class.format(example_changes,
                                        tag_delete: 'span',
                                        class_delete: 'deleted',
                                        tag_insert: 'span',
                                        class_insert: 'inserted',
                                        tag_replace: 'mark',
                                        class_replace: 'replaced')

        expected = 'The <span class="deleted">quick </span>red fox ' \
                   '<mark class="replaced">jumped</mark><mark class="replaced">hopped</mark> ' \
                   'over the <span class="inserted">lazy </span>dog.'
        expect(result).to eq(expected)
      end
    end

    context 'with tag but no class specified' do
      it 'uses the tag without a class attribute' do
        result = described_class.format(example_changes, tag: 'span')

        expected = 'The <span>quick </span>red fox <span>jumped</span><span>hopped</span> over the <span>lazy </span>dog.'
        expect(result).to eq(expected)
      end
    end

    context 'with empty class array' do
      it 'omits the class attribute' do
        result = described_class.format(example_changes,
                                        tag: 'span',
                                        class_delete: [],
                                        class_insert: [])

        expected = 'The <span>quick </span>red fox <span>jumped</span><span>hopped</span> over the <span>lazy </span>dog.'
        expect(result).to eq(expected)
      end
    end

    context 'with different classes for replacement parts' do
      it 'applies specific classes to replaced content' do
        result = described_class.format(example_changes,
                                        tag: 'span',
                                        class_delete: 'deleted',
                                        class_insert: 'inserted',
                                        class_replace_delete: 'old-text',
                                        class_replace_insert: 'new-text')

        expected = 'The <span class="deleted">quick </span>red fox ' \
                   '<span class="old-text">jumped</span><span class="new-text">hopped</span> ' \
                   'over the <span class="inserted">lazy </span>dog.'
        expect(result).to eq(expected)
      end
    end

    context 'with tags containing angle brackets' do
      it 'cleans up tag names with angle brackets' do
        result = described_class.format(example_changes,
                                        tag_delete: '<span>',
                                        tag_insert: '<span>')

        expected = 'The <span>quick </span>red fox <span>jumped</span><span>hopped</span> over the <span>lazy </span>dog.'
        expect(result).to eq(expected)
      end
    end

    context 'with nil content' do
      it 'handles nil old_string in equal action' do
        changes = [['=', nil, 'some text']]
        result = described_class.format(changes)
        expect(result).to eq('some text')
      end

      it 'handles nil new_string in equal action' do
        changes = [['=', 'some text', nil]]
        result = described_class.format(changes)
        expect(result).to eq('')
      end

      it 'handles nil old_string in remove action' do
        changes = [['-', nil, 'some text']]
        result = described_class.format(changes)
        expect(result).to eq('')
      end

      it 'handles nil new_string in add action' do
        changes = [['+', 'some text', nil]]
        result = described_class.format(changes)
        expect(result).to eq('')
      end

      it 'handles nil old_string in replace action' do
        changes = [['!', nil, 'new text']]
        result = described_class.format(changes)
        expect(result).to eq('<ins>new text</ins>')
      end

      it 'handles nil new_string in replace action' do
        changes = [['!', 'old text', nil]]
        result = described_class.format(changes)
        expect(result).to eq('<del>old text</del>')
      end
    end

    context 'with HTML special characters' do
      let(:changes) { [['=', '<div>content</div>', '<div>content</div>']] }

      it 'does not escape HTML in the content' do
        result = described_class.format(changes)
        expect(result).to eq('<div>content</div>')
      end

      it 'safely wraps HTML with del tags when removed' do
        changes = [['-', '<strong>bold</strong>', nil]]
        result = described_class.format(changes)
        expect(result).to eq('<del><strong>bold</strong></del>')
      end

      it 'safely wraps HTML with ins tags when added' do
        changes = [['+', nil, '<em>emphasis</em>']]
        result = described_class.format(changes)
        expect(result).to eq('<ins><em>emphasis</em></ins>')
      end
    end

    context 'with whitespace handling' do
      it 'preserves whitespace in equal content' do
        changes = [['=', "Line with\nbreaks and    spaces", "Line with\nbreaks and    spaces"]]
        result = described_class.format(changes)
        expect(result).to eq("Line with\nbreaks and    spaces")
      end

      it 'preserves whitespace in removed content' do
        changes = [['-', "Text with\ttabs", nil]]
        result = described_class.format(changes)
        expect(result).to eq('<del>Text with	tabs</del>')
      end

      it 'preserves whitespace in added content' do
        changes = [['+', nil, "Text with  \nmultiple spaces"]]
        result = described_class.format(changes)
        expect(result).to eq("<ins>Text with  \nmultiple spaces</ins>")
      end
    end
  end

  describe '.html_tag' do
    it 'creates an HTML tag with the specified attributes' do
      result = described_class.send(:html_tag, 'span', 'highlight', 'content')
      expect(result).to eq('<span class="highlight">content</span>')
    end

    it 'returns empty string when content is nil' do
      result = described_class.send(:html_tag, 'span', 'highlight', nil)
      expect(result).to eq('')
    end

    it 'creates a tag without class when class is nil' do
      result = described_class.send(:html_tag, 'span', nil, 'content')
      expect(result).to eq('<span>content</span>')
    end

    it 'handles tags with angle brackets' do
      result = described_class.send(:html_tag, '<div>', 'container', 'content')
      expect(result).to eq('<div class="container">content</div>')
    end
  end
end
