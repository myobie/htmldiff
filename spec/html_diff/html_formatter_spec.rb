# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff::HtmlFormatter do
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

  shared_examples 'common formatter behavior' do
    context 'with equal content' do
      let(:changes) { [['=', 'This is some text', 'This is some text']] }

      it 'preserves unchanged content without markup' do
        expect(result).to eq('This is some text')
      end
    end

    context 'with nil content' do
      context 'with equal action' do
        context 'with nil old_string' do
          let(:changes) { [['=', nil, 'some text']] }

          it 'handles nil old_string' do
            expect(result).to eq('some text')
          end
        end

        context 'with nil new_string' do
          let(:changes) { [['=', 'some text', nil]] }

          it 'handles nil new_string' do
            expect(result).to eq('')
          end
        end
      end

      context 'with remove action' do
        context 'with nil old_string' do
          let(:changes) { [['-', nil, 'some text']] }

          it 'handles nil old_string' do
            expect(result).to eq('')
          end
        end
      end

      context 'with add action' do
        context 'with nil new_string' do
          let(:changes) { [['+', 'some text', nil]] }

          it 'handles nil new_string' do
            expect(result).to eq('')
          end
        end
      end
    end

    context 'with empty changes array' do
      let(:changes) { [] }

      it 'returns empty string for empty changes array' do
        expect(result).to eq('')
      end
    end

    context 'with whitespace handling' do
      context 'with equal content' do
        let(:changes) { [['=', "Line with\nbreaks and    spaces", "Line with\nbreaks and    spaces"]] }

        it 'preserves whitespace in equal content' do
          expect(result).to eq("Line with\nbreaks and    spaces")
        end
      end
    end
  end

  describe '.format' do
    context 'with default options' do
      let(:result) { described_class.format(changes) }

      it 'generates the expected HTML' do
        result = described_class.format(example_changes)
        expected = 'The <del>quick </del>red fox <del>jumped</del><ins>hopped</ins> over the <ins>lazy </ins>dog.'
        expect(result).to eq(expected)
      end


      it_behaves_like 'common formatter behavior'

      context 'with removed content' do
        let(:changes) { [['-', 'deleted text', nil]] }

        it 'wraps deleted content in del tags by default' do
          expect(result).to eq('<del>deleted text</del>')
        end
      end

      context 'with added content' do
        let(:changes) { [['+', nil, 'added text']] }

        it 'wraps added content in ins tags by default' do
          expect(result).to eq('<ins>added text</ins>')
        end
      end

      context 'with replaced content' do
        let(:changes) { [['!', 'old text', 'new text']] }

        it 'shows both deleted and inserted content with default tags' do
          expect(result).to eq('<del>old text</del><ins>new text</ins>')
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
          expected = 'This is <del>removed </del>and <ins>added </ins>' \
                     '<del>modified text</del><ins>changed text</ins> at the end'
          expect(result).to eq(expected)
        end
      end

      context 'with HTML special characters' do
        context 'with equal content' do
          let(:changes) { [['=', '<div>content</div>', '<div>content</div>']] }

          it 'does not escape HTML in the content' do
            expect(result).to eq('<div>content</div>')
          end
        end

        context 'with removed content' do
          let(:changes) { [['-', '<strong>bold</strong>', nil]] }

          it 'safely wraps HTML with del tags when removed' do
            expect(result).to eq('<del><strong>bold</strong></del>')
          end
        end

        context 'with added content' do
          let(:changes) { [['+', nil, '<em>emphasis</em>']] }

          it 'safely wraps HTML with ins tags when added' do
            expect(result).to eq('<ins><em>emphasis</em></ins>')
          end
        end
      end

      context 'with whitespace handling' do
        context 'with removed content' do
          let(:changes) { [['-', "Text with\ttabs", nil]] }

          it 'preserves whitespace in removed content' do
            expect(result).to eq("<del>Text with\ttabs</del>")
          end
        end

        context 'with added content' do
          let(:changes) { [['+', nil, "Text with  \nmultiple spaces"]] }

          it 'preserves whitespace in added content' do
            expect(result).to eq("<ins>Text with  \nmultiple spaces</ins>")
          end
        end
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
                                        tag_unchanged: 'span',
                                        class_unchanged: 'unchanged',
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

    context 'with class arguments' do
      let(:result) do
        described_class.format(changes,
                               class_delete: 'diffdel',
                               class_insert: 'diffins',
                               class_replace: 'diffmod')
      end

      it_behaves_like 'common formatter behavior'

      context 'with removed content' do
        let(:changes) { [['-', 'deleted text', nil]] }

        it 'wraps deleted content in del tags with diffdel class' do
          expect(result).to eq('<del class="diffdel">deleted text</del>')
        end
      end

      context 'with added content' do
        let(:changes) { [['+', nil, 'added text']] }

        it 'wraps added content in ins tags with diffins class' do
          expect(result).to eq('<ins class="diffins">added text</ins>')
        end
      end

      context 'with replaced content' do
        let(:changes) { [['!', 'old text', 'new text']] }

        it 'shows both deleted and inserted content with diffmod class' do
          expect(result).to eq('<del class="diffmod">old text</del><ins class="diffmod">new text</ins>')
        end
      end

      context 'with replace action and nil values' do
        context 'with nil old_string' do
          let(:changes) { [['!', nil, 'new text']] }

          it 'handles nil old_string in replace action' do
            expect(result).to eq('<ins class="diffmod">new text</ins>')
          end
        end

        context 'with nil new_string' do
          let(:changes) { [['!', 'old text', nil]] }

          it 'handles nil new_string in replace action' do
            expect(result).to eq('<del class="diffmod">old text</del>')
          end
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
          expected = 'This is <del class="diffdel">removed </del>and <ins class="diffins">added </ins>' \
                     '<del class="diffmod">modified text</del><ins class="diffmod">changed text</ins> at the end'
          expect(result).to eq(expected)
        end
      end

      context 'with HTML special characters' do
        context 'with equal action' do
          let(:changes) { [['=', '<div>content</div>', '<div>content</div>']] }

          it 'does not escape HTML in the content' do
            expect(result).to eq('<div>content</div>')
          end
        end

        context 'with remove action' do
          let(:changes) { [['-', '<strong>bold</strong>', nil]] }

          it 'safely wraps HTML with del tags when removed' do
            expect(result).to eq('<del class="diffdel"><strong>bold</strong></del>')
          end
        end

        context 'with add action' do
          let(:changes) { [['+', nil, '<em>emphasis</em>']] }

          it 'safely wraps HTML with ins tags when added' do
            expect(result).to eq('<ins class="diffins"><em>emphasis</em></ins>')
          end
        end
      end

      context 'with whitespace handling' do
        context 'with removed content' do
          let(:changes) { [['-', "Text with\ttabs", nil]] }

          it 'preserves whitespace in removed content' do
            expect(result).to eq('<del class="diffdel">Text with	tabs</del>')
          end
        end

        context 'with added content' do
          let(:changes) { [['+', nil, "Text with  \nmultiple spaces"]] }

          it 'preserves whitespace in added content' do
            expect(result).to eq("<ins class=\"diffins\">Text with  \nmultiple spaces</ins>")
          end
        end
      end
    end

    context 'with tag and class arguments' do
      let(:result) do
        described_class.format(changes,
                               tag: 'span',
                               class_delete: 'diff-del',
                               class_insert: 'diff-ins',
                               class_replace_delete: 'diff-mod diff-del',
                               class_replace_insert: 'diff-mod diff-ins')
      end

      it_behaves_like 'common formatter behavior'

      context 'with removed content' do
        let(:changes) { [['-', 'deleted text', nil]] }

        it 'wraps deleted content in span tags with diff-del class' do
          expect(result).to eq('<span class="diff-del">deleted text</span>')
        end
      end

      context 'with added content' do
        let(:changes) { [['+', nil, 'added text']] }

        it 'wraps added content in span tags with diff-ins class' do
          expect(result).to eq('<span class="diff-ins">added text</span>')
        end
      end

      context 'with replaced content' do
        let(:changes) { [['!', 'old text', 'new text']] }

        it 'shows both deleted and inserted content with diff-mod classes' do
          expect(result).to eq('<span class="diff-mod diff-del">old text</span><span class="diff-mod diff-ins">new text</span>')
        end
      end

      context 'with replace action and nil values' do
        context 'with nil old_string' do
          let(:changes) { [['!', nil, 'new text']] }

          it 'handles nil old_string in replace action' do
            expect(result).to eq('<span class="diff-mod diff-ins">new text</span>')
          end
        end

        context 'with nil new_string' do
          let(:changes) { [['!', 'old text', nil]] }

          it 'handles nil new_string in replace action' do
            expect(result).to eq('<span class="diff-mod diff-del">old text</span>')
          end
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
          expected = 'This is <span class="diff-del">removed </span>and <span class="diff-ins">added </span>' \
                     '<span class="diff-mod diff-del">modified text</span><span class="diff-mod diff-ins">changed text</span> at the end'
          expect(result).to eq(expected)
        end
      end

      context 'with HTML special characters' do
        context 'with equal action' do
          let(:changes) { [['=', '<div>content</div>', '<div>content</div>']] }

          it 'does not escape HTML in the content' do
            expect(result).to eq('<div>content</div>')
          end
        end

        context 'with remove action' do
          let(:changes) { [['-', '<strong>bold</strong>', nil]] }

          it 'safely wraps HTML with span tags when removed' do
            expect(result).to eq('<span class="diff-del"><strong>bold</strong></span>')
          end
        end

        context 'with add action' do
          let(:changes) { [['+', nil, '<em>emphasis</em>']] }

          it 'safely wraps HTML with span tags when added' do
            expect(result).to eq('<span class="diff-ins"><em>emphasis</em></span>')
          end
        end
      end

      context 'with whitespace handling' do
        context 'with removed content' do
          let(:changes) { [['-', "Text with\ttabs", nil]] }

          it 'preserves whitespace in removed content' do
            expect(result).to eq('<span class="diff-del">Text with	tabs</span>')
          end
        end

        context 'with added content' do
          let(:changes) { [['+', nil, "Text with  \nmultiple spaces"]] }

          it 'preserves whitespace in added content' do
            expect(result).to eq("<span class=\"diff-ins\">Text with  \nmultiple spaces</span>")
          end
        end
      end
    end

    context 'with complex combinations of options' do
      let(:changes) { example_changes }

      it 'handles complex tag and class hierarchies' do
        result = described_class.format(changes,
                                        tag: 'span',
                                        class: 'base',
                                        tag_delete: 'del',
                                        class_delete: 'deleted',
                                        tag_insert: 'ins',
                                        class_insert: 'inserted',
                                        tag_replace: 'mark',
                                        class_replace: 'replaced',
                                        tag_replace_delete: 'del',
                                        class_replace_delete: 'replaced-del',
                                        tag_replace_insert: 'ins',
                                        class_replace_insert: 'replaced-ins')

        expected = 'The <del class="deleted">quick </del>red fox ' \
                   '<del class="replaced-del">jumped</del><ins class="replaced-ins">hopped</ins> ' \
                   'over the <ins class="inserted">lazy </ins>dog.'
        expect(result).to eq(expected)
      end

      it 'handles all tag options with null classes' do
        result = described_class.format(changes,
                                        tag_unchanged: 'span',
                                        tag_delete: 'del',
                                        tag_insert: 'ins',
                                        tag_replace: 'mark',
                                        tag_replace_delete: 'span',
                                        tag_replace_insert: 'span',
                                        class: nil)

        expected = '<span>The </span><del>quick </del><span>red fox </span>' \
                   '<span>jumped</span><span>hopped</span><span> over the </span>' \
                   '<ins>lazy </ins><span>dog.</span>'
        expect(result).to eq(expected)
      end
    end

    context 'with replace action when one string is nil' do
      it 'handles replace with nil old_string' do
        changes = [['!', nil, 'new text']]
        result = described_class.format(changes)
        expect(result).to eq('<ins>new text</ins>')
      end

      it 'handles replace with nil new_string' do
        changes = [['!', 'old text', nil]]
        result = described_class.format(changes)
        expect(result).to eq('<del>old text</del>')
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

    it 'handles unusual class values' do
      result = described_class.send(:html_tag, 'div', '', 'content')
      expect(result).to eq('<div>content</div>')
      result = described_class.send(:html_tag, 'div', false, 'content')
      expect(result).to eq('<div>content</div>')
    end

    it 'joins array class values with spaces' do
      result = described_class.send(:html_tag, 'div', %w[one two three], 'content')
      expect(result).to eq('<div class="one two three">content</div>')
    end

    it 'handles empty array for class' do
      result = described_class.send(:html_tag, 'div', [], 'content')
      expect(result).to eq('<div>content</div>')
    end
  end
end
