# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe HTMLDiff::Formatters::LegacyFormatter do
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

      it 'wraps deleted content in del tags with diffdel class' do
        result = described_class.format(changes)
        expect(result).to eq('<del class="diffdel">deleted text</del>')
      end
    end

    context 'with added content' do
      let(:changes) { [['+', nil, 'added text']] }

      it 'wraps added content in ins tags with diffins class' do
        result = described_class.format(changes)
        expect(result).to eq('<ins class="diffins">added text</ins>')
      end
    end

    context 'with replaced content' do
      let(:changes) { [['!', 'old text', 'new text']] }

      it 'shows both deleted and inserted content with diffmod class' do
        result = described_class.format(changes)
        expect(result).to eq('<del class="diffmod">old text</del><ins class="diffmod">new text</ins>')
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

      it 'handles nil content in replace action' do
        changes = [['!', nil, 'new text']]
        result = described_class.format(changes)
        expect(result).to eq('<ins class="diffmod">new text</ins>')
      end

      it 'handles nil content in replace action' do
        changes = [['!', 'old text', nil]]
        result = described_class.format(changes)
        expect(result).to eq('<del class="diffmod">old text</del>')
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
        expected = 'This is <del class="diffdel">removed </del>and <ins class="diffins">added </ins>' \
          '<del class="diffmod">modified text</del><ins class="diffmod">changed text</ins> at the end'
        expect(result).to eq(expected)
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
        expect(result).to eq('<del class="diffdel"><strong>bold</strong></del>')
      end

      it 'safely wraps HTML with ins tags when added' do
        changes = [['+', nil, '<em>emphasis</em>']]
        result = described_class.format(changes)
        expect(result).to eq('<ins class="diffins"><em>emphasis</em></ins>')
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
        expect(result).to eq('<del class="diffdel">Text with	tabs</del>')
      end

      it 'preserves whitespace in added content' do
        changes = [['+', nil, "Text with  \nmultiple spaces"]]
        result = described_class.format(changes)
        expect(result).to eq("<ins class=\"diffins\">Text with  \nmultiple spaces</ins>")
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
  end
end
