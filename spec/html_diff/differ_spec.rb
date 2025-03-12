# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff::Differ do
  describe '.diff' do
    let(:result) { described_class.diff(old_tokens, new_tokens) }

    context 'with identical sequences' do
      let(:old_tokens) { ['apple', ' ', 'banana', ' ', 'cherry'] }
      let(:new_tokens) { ['apple', ' ', 'banana', ' ', 'cherry'] }

      it 'returns an array with equality operations' do
        expect(result).to eq([['=', 'apple banana cherry', 'apple banana cherry']])
      end
    end

    context 'with additions' do
      let(:old_tokens) { ['apple', ' ', 'cherry'] }
      let(:new_tokens) { ['apple', ' ', 'banana', ' ', 'cherry'] }

      it 'returns operations with insertions' do
        expect(result).to eq([
                               ['=', 'apple ', 'apple '],
                               ['+', nil, 'banana '],
                               ['=', 'cherry', 'cherry']
                             ])
      end

      context 'with consecutive additions' do
        let(:old_tokens) { ['apple', ' ', 'elderberry'] }
        let(:new_tokens) { ['apple', ' ', 'banana', ' ', 'cherry', ' ', 'elderberry'] }

        it 'joins consecutive additions' do
          expect(result).to eq([
                                 ['=', 'apple ', 'apple '],
                                 ['+', nil, 'banana cherry '],
                                 ['=', 'elderberry', 'elderberry']
                               ])
        end
      end
    end

    context 'with deletions' do
      let(:old_tokens) { ['apple', ' ', 'banana', ' ', 'cherry'] }
      let(:new_tokens) { ['apple', ' ', 'cherry'] }

      it 'returns operations with deletions' do
        expect(result).to eq([
                               ['=', 'apple ', 'apple '],
                               ['-', 'banana ', nil],
                               ['=', 'cherry', 'cherry']
                             ])
      end

      context 'with consecutive deletions' do
        let(:old_tokens) { ['apple', ' ', 'banana', ' ', 'cherry', ' ', 'elderberry'] }
        let(:new_tokens) { ['apple', ' ', 'elderberry'] }

        it 'joins consecutive deletions' do
          expect(result).to eq([
                                 ['=', 'apple ', 'apple '],
                                 ['-', 'banana cherry ', nil],
                                 ['=', 'elderberry', 'elderberry']
                               ])
        end
      end
    end

    context 'with replacements' do
      let(:old_tokens) { ['apple', ' ', 'banana', ' ', 'cherry'] }
      let(:new_tokens) { ['apple', ' ', 'orange', ' ', 'cherry'] }

      it 'handles replacements' do
        expect(result).to eq([
                               ['=', 'apple ', 'apple '],
                               ['!', 'banana', 'orange'],
                               ['=', ' cherry', ' cherry']
                             ])
      end

      context 'with consecutive replacements' do
        let(:old_tokens) { ['apple', ' ', 'banana', ' ', 'cherry', ' ', 'elderberry'] }
        let(:new_tokens) { ['apple', ' ', 'orange', ' ', 'kiwi', ' ', 'elderberry'] }

        it 'handles each replacement separately' do
          expect(result).to eq([
                                 ['=', 'apple ', 'apple '],
                                 ['!', 'banana cherry', 'orange kiwi'],
                                 ['=', ' elderberry', ' elderberry']
                               ])
        end
      end
    end

    context 'with mixed operations and joins' do
      context 'with a delete followed by an insert' do
        let(:old_tokens) { ['apple', ' ', 'banana', ' ', 'cherry'] }
        let(:new_tokens) { ['apple', ' ', 'orange', ' ', 'cherry'] }

        it 'combines deletion followed by insertion into replacement' do
          expect(result).to eq([
                                 ['=', 'apple ', 'apple '],
                                 ['!', 'banana', 'orange'],
                                 ['=', ' cherry', ' cherry']
                               ])
        end
      end

      context 'with an insert followed by a delete' do
        let(:old_tokens) { ['apple', ' ', 'banana', ' ', 'elderberry'] }
        let(:new_tokens) { ['apple', ' ', 'orange', ' ', 'elderberry'] }

        it 'combines insertion followed by deletion into replacement' do
          expect(result).to eq([
                                 ['=', 'apple ', 'apple '],
                                 ['!', 'banana', 'orange'],
                                 ['=', ' elderberry', ' elderberry']
                               ])
        end
      end

      context 'with mixed operation patterns' do
        let(:old_tokens) { ['apple', ' ', 'banana', ' ', 'cherry', ' ', 'date', ' ', 'elderberry'] }
        let(:new_tokens) { ['apple', ' ', 'orange', ' ', 'kiwi', ' ', 'date', ' ', 'grape'] }

        it 'properly joins consecutive operations of the same type' do
          expect(result).to eq([
                                 ['=', 'apple ', 'apple '],
                                 ['!', 'banana cherry', 'orange kiwi'],
                                 ['=', ' date ', ' date '],
                                 ['!', 'elderberry', 'grape']
                               ])
        end
      end
    end

    context 'with joining behavior' do
      context 'when a replacement is followed by a deletion' do
        let(:old_tokens) { ['apple', ' ', 'banana', ' ', 'cherry', ' ', 'date'] }
        let(:new_tokens) { ['apple', ' ', 'orange', ' ', 'date'] }

        it 'correctly handles replacement followed by deletion' do
          expect(result).to eq([
                                 ['=', 'apple ', 'apple '],
                                 ['!', 'banana cherry', 'orange'],
                                 ['=', ' date', ' date']
                               ])
        end
      end

      context 'when a replacement is followed by an insertion' do
        let(:old_tokens) { ['apple', ' ', 'banana', ' ', 'date'] }
        let(:new_tokens) { ['apple', ' ', 'orange', ' ', 'cherry', ' ', 'date'] }

        it 'correctly handles replacement followed by insertion' do
          expect(result).to eq([
                                 ['=', 'apple ', 'apple '],
                                 ['!', 'banana', 'orange cherry'],
                                 ['=', ' date', ' date']
                               ])
        end
      end
    end

    context 'with edge cases' do
      context 'with empty sequences' do
        let(:old_tokens) { [] }
        let(:new_tokens) { [] }

        it 'handles empty sequences' do
          expect(result).to eq([])
        end
      end

      context 'with one empty sequence' do
        context 'with empty old_tokens' do
          let(:old_tokens) { [] }
          let(:new_tokens) { ['apple', ' ', 'banana', ' ', 'cherry'] }

          it 'handles empty old_tokens' do
            expect(result).to eq([['+', nil, 'apple banana cherry']])
          end
        end

        context 'with empty new_tokens' do
          let(:old_tokens) { ['apple', ' ', 'banana', ' ', 'cherry'] }
          let(:new_tokens) { [] }

          it 'handles empty new_tokens' do
            expect(result).to eq([['-', 'apple banana cherry', nil]])
          end
        end
      end

      context 'with whitespace-only changes' do
        let(:old_tokens) { ['apple', ' ', 'banana'] }
        let(:new_tokens) { ['apple', ' ', ' ', 'banana'] }

        it 'correctly identifies whitespace changes' do
          expect(result).to eq([
                                 ['=', 'apple ', 'apple '],
                                 ['+', nil, ' '],
                                 ['=', 'banana', 'banana']
                               ])
        end
      end

      it 'handles multiple whitespace characters' do
        old_tokens = ['high', ' ', ' ', 'performance']
        new_tokens = ['high', ' ', 'speed', ' ', 'performance']

        result = HTMLDiff::Differ.diff(old_tokens, new_tokens)

        expect(result).to eq([
                               ["=", "high ", "high "],
                               ["+", nil, "speed"],
                               ["=", " performance", " performance"]
                             ])
      end

      it 'generates a simplified diff from two sequences' do
        old_tokens = ['The', ' ', 'quick', ' ', 'brown', ' ', 'fox']
        new_tokens = ['The', ' ', 'fast', ' ', 'brown', ' ', 'fox']

        result = HTMLDiff::Differ.diff(old_tokens, new_tokens)

        expect(result).to eq([
                               ['=', 'The ', 'The '],
                               ['!', 'quick', 'fast'],
                               ['=', ' brown fox', ' brown fox']
                             ])
      end

      it 'joins consecutive operations of the same type across whitespaces' do
        old_tokens = ['The', ' ', 'quick', ' ', 'brown', ' ', 'fox', ' ', 'jumps']
        new_tokens = ['The', ' ', 'fast', ' ', 'speedy', ' ', 'fox', ' ', 'leaps']

        result = HTMLDiff::Differ.diff(old_tokens, new_tokens)

        expect(result).to eq([
                               ['=', 'The ', 'The '],
                               ['!', 'quick brown', 'fast speedy'],
                               ['=', ' fox ', ' fox '],
                               ['!', 'jumps', 'leaps']
                             ])
      end
    end
  end
end
