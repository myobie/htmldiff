# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe HTMLDiff::Formatters::SpanFormatter do
  describe '.format' do
    context 'with equal content' do
      let(:changes) { [['=', 'This is some text', 'This is some text']] }

      it 'preserves unchanged content without markup' do
        result = described_class.format(changes)
        expect(result).to eq('This is some text')
      end
    end

    context 'with removed content' do
      let(:changes) { [['-', 'deleted text', nil]] }

      it 'wraps deleted content in span tags with diff-remove class' do
        result = described_class.format(changes)
        expect(result).to eq('<span class="diff-remove">deleted text</span>')
      end
    end

    context 'with added content' do
      let(:changes) { [['+', nil, 'added text']] }

      it 'wraps added content in span tags with diff-add class' do
        result = described_class.format(changes)
        expect(result).to eq('<span class="diff-add">added text</span>')
      end
    end

    context 'with replaced content' do
      let(:changes) { [['!', 'old text', 'new text']] }

      it 'shows both deleted and inserted content with diff-replace classes' do
        result = described_class.format(changes)
        expect(result).to eq('<span class="diff-replace diff-remove">old text</span><span class="diff-replace diff-add">new text</span>')
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
        expect(result).to eq('<span class="diff-replace diff-add">new text</span>')
      end

      it 'handles nil new_string in replace action' do
        changes = [['!', 'old text', nil]]
        result = described_class.format(changes)
        expect(result).to eq('<span class="diff-replace diff-remove">old text</span>')
      end
    end

    context 'with mixed content' do
      let(:changes) do
        [
          ['=', 'This is ', 'This is '],
          ['-', 'removed ', nil],
          ['=', 'and ', 'and '],
          ['+', nil, 'added '],
          ['!', 'modified text', 'changed text'],
          ['=', ' at the end', ' at the end']
        ]
      end

      it 'formats mixed content correctly' do
        result = described_class.format(changes)
        expected = 'This is <span class="diff-remove">removed </span>and <span class="diff-add">added </span>' \
                   '<span class="diff-replace diff-remove">modified text</span><span class="diff-replace diff-add">changed text</span> at the end'
        expect(result).to eq(expected)
      end
    end

    context 'with HTML special characters' do
      let(:changes) { [['=', '<div>content</div>', '<div>content</div>']] }

      it 'does not escape HTML in the content' do
        result = described_class.format(changes)
        expect(result).to eq('<div>content</div>')
      end

      it 'safely wraps HTML with span tags when removed' do
        changes = [['-', '<strong>bold</strong>', nil]]
        result = described_class.format(changes)
        expect(result).to eq('<span class="diff-remove"><strong>bold</strong></span>')
      end

      it 'safely wraps HTML with span tags when added' do
        changes = [['+', nil, '<em>emphasis</em>']]
        result = described_class.format(changes)
        expect(result).to eq('<span class="diff-add"><em>emphasis</em></span>')
      end
    end

    context 'with empty changes array' do
      let(:changes) { [] }

      it 'returns empty string for empty changes array' do
        result = described_class.format(changes)
        expect(result).to eq('')
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
        expect(result).to eq('<span class="diff-remove">Text with	tabs</span>')
      end

      it 'preserves whitespace in added content' do
        changes = [['+', nil, "Text with  \nmultiple spaces"]]
        result = described_class.format(changes)
        expect(result).to eq("<span class=\"diff-add\">Text with  \nmultiple spaces</span>")
      end
    end
  end

  describe '.span_tag' do
    it 'creates a span tag with the specified attributes' do
      result = described_class.send(:span_tag, 'highlight', 'content')
      expect(result).to eq('<span class="highlight">content</span>')
    end

    it 'returns empty string when content is nil' do
      result = described_class.send(:span_tag, 'highlight', nil)
      expect(result).to eq('')
    end
  end
end
