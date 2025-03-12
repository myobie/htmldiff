# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff::Differ do
  describe '.diff' do
    let(:result) { described_class.diff(old_tokens, new_tokens) }

    context 'basic case' do # rubocop:disable RSpec/ContextWording
      let(:old_tokens) { ['a', ' ', 'word', ' ', 'now', ' ', 'is', ' ', 'here'] }
      let(:new_tokens) { ['a', ' ', 'second', ' ', 'word', ' ', 'is', ' ', 'there'] }

      it 'returns an array with equality operations' do
        expect(result).to eq([
                               ['=', 'a ', 'a '],
                               ['+', nil, 'second '],
                               ['=', 'word ', 'word '],
                               ['!', 'now is here', 'is there']
                             ])
      end
    end

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

      context 'with trailing words' do
        let(:old_tokens) { ['The', ' ', 'quick', ' ', 'brown', ' ', 'fox'] }
        let(:new_tokens) { ['The', ' ', 'fast', ' ', 'brown', ' ', 'fox'] }

        it 'handles replacements' do
          expect(result).to eq([
                                 ['=', 'The ', 'The '],
                                 ['!', 'quick', 'fast'],
                                 ['=', ' brown fox', ' brown fox']
                               ])
        end
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

    context 'edge cases' do # rubocop:disable RSpec/ContextWording
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

      context 'with multiple whitespace characters' do
        let(:old_tokens) { ['high', ' ', ' ', 'performance'] }
        let(:new_tokens) { ['high', ' ', 'speed', ' ', 'performance'] }

        it 'correctly inserts the word' do
          expect(result).to eq([
                                 ['=', 'high ', 'high '],
                                 ['+', nil, 'speed'],
                                 ['=', ' performance', ' performance']
                               ])
        end
      end
    end

    context 'when merge joining' do
      context 'with mergeable segment between replacements with mergeable string' do
        let(:old_tokens) { ['The', ' ', 'quick', ' ', 'brown', ' ', 'fox', ' ', 'jumps'] }
        let(:new_tokens) { ['The', ' ', 'fast', ' ', 'speedy', ' ', 'fox', ' ', 'leaps'] }

        it 'joins consecutive operations of the same type across the mergeable segment' do
          expect(result).to eq([
                                 ['=', 'The ', 'The '],
                                 ['!', 'quick brown fox jumps', 'fast speedy fox leaps']
                               ])
        end
      end

      context 'with mergeable segment between replacements with non-mergeable string' do
        let(:old_tokens) { ['The', ' ', 'quick', ' ', 'brown', ' ', 'toad', ' ', 'jumps'] }
        let(:new_tokens) { ['The', ' ', 'fast', ' ', 'speedy', ' ', 'toad', ' ', 'leaps'] }

        it 'joins consecutive operations of the same type across mergeable segments' do
          expect(result).to eq([
                                 ['=', 'The ', 'The '],
                                 ['!', 'quick brown', 'fast speedy'],
                                 ['=', ' toad ', ' toad '],
                                 ['!', 'jumps', 'leaps']
                               ])
        end
      end

      context 'with mergeable segment between inserts' do
        let(:old_tokens) { ['&#8364;', ' ', 'is', ' ', 'euro'] }
        let(:new_tokens) { ['&#8364;', ' ', 'is', ' ', 'the', ' ', 'euro', ' ', 'symbol'] }

        it 'does not join whitespace' do
          expect(result).to eq([
                                 ['=', '&#8364; is ', '&#8364; is '],
                                 ['+', nil, 'the '],
                                 ['=', 'euro', 'euro'],
                                 ['+', nil, ' symbol']
                               ])
        end
      end

      context 'with mergeable segment between deletes' do
        let(:old_tokens) { ['&#8364;', ' ', 'is', ' ', 'the', ' ', 'euro', ' ', 'symbol'] }
        let(:new_tokens) { ['&#8364;', ' ', 'is', ' ', 'euro'] }

        it 'does not join whitespace' do
          expect(result).to eq([
                                 ['=', '&#8364; is ', '&#8364; is '],
                                 ['-', 'the ', nil],
                                 ['=', 'euro', 'euro'],
                                 ['-', ' symbol', nil]
                               ])
        end
      end

      context 'with mergeable segment between insert and delete' do
        let(:old_tokens) { ['&#8364;', ' ', 'is', ' ', 'the', ' ', 'euro'] }
        let(:new_tokens) { ['&#8364;', ' ', 'is', ' ', 'euro', ' ', 'symbol'] }

        it 'does not join whitespace' do
          expect(result).to eq([
                                 ['=', '&#8364; is ', '&#8364; is '],
                                 ['-', 'the ', nil],
                                 ['=', 'euro', 'euro'],
                                 ['+', nil, ' symbol']
                               ])
        end
      end

      context 'with mergeable segment between replacement and insert' do
        let(:old_tokens) { ['&#8364;', ' ', 'is', ' ', 'the', ' ', 'euro'] }
        let(:new_tokens) { ['&#8364;', ' ', 'is', ' ', 'a', ' ', 'euro', ' ', 'symbol'] }

        it 'joins consecutive operations of the same type across whitespaces' do
          expect(result).to eq([
                                 ['=', '&#8364; is ', '&#8364; is '],
                                 ['!', 'the euro', 'a euro symbol']
                               ])
        end
      end

      context 'with mergeable segment between replacement and delete' do
        let(:old_tokens) { ['&#8364;', ' ', 'is', ' ', 'the', ' ', 'euro', ' ', 'symbol'] }
        let(:new_tokens) { ['&#8364;', ' ', 'is', ' ', 'a', ' ', 'euro'] }

        it 'joins consecutive operations of the same type across whitespaces' do
          expect(result).to eq([
                                 ['=', '&#8364; is ', '&#8364; is '],
                                 ['!', 'the euro symbol', 'a euro']
                               ])
        end
      end

      context 'with mergeable segment between insert and replacement' do
        let(:old_tokens) { ['&#8364;', ' ', 'is', ' ', 'euro', ' ', 'mark'] }
        let(:new_tokens) { ['&#8364;', ' ', 'is', ' ', 'a', ' ', 'euro', ' ', 'symbol'] }

        it 'joins consecutive operations of the same type across whitespaces' do
          expect(result).to eq([
                                 ['=', '&#8364; is ', '&#8364; is '],
                                 ['!', 'euro mark', 'a euro symbol']
                               ])
        end
      end

      context 'with mergeable segment between delete and replacement' do
        let(:old_tokens) { ['&#8364;', ' ', 'is', ' ', 'a', ' ', 'euro', ' ', 'mark'] }
        let(:new_tokens) { ['&#8364;', ' ', 'is', ' ', 'euro', ' ', 'symbol'] }

        it 'joins consecutive operations of the same type across whitespaces' do
          expect(result).to eq([
                                 ['=', '&#8364; is ', '&#8364; is '],
                                 ['!', 'a euro mark', 'euro symbol']
                               ])
        end
      end

      context 'with non-mergeable segment between two replacements' do
        let(:old_tokens) { ['&#8364;', ' ', 'is', ' ', 'the', ' ', 'euro', ' ', 'symbol'] }
        let(:new_tokens) { ['&#8364;', ' ', 'is', ' ', 'a', ' ', 'euro', ' ', 'mark'] }

        it 'joins consecutive operations of the same type across whitespaces' do
          expect(result).to eq([
                                 ['=', '&#8364; is ', '&#8364; is '],
                                 ['!', 'the', 'a'],
                                 ['=', ' euro ', ' euro '],
                                 ['!', 'symbol', 'mark']
                               ])
        end
      end

      context 'with mergeable segment between two replacements' do
        let(:old_tokens) { ['&yen;', ' ', 'is', ' ', 'the', ' ', 'yen', ' ', 'symbol'] }
        let(:new_tokens) { ['&yen;', ' ', 'is', ' ', 'a', ' ', 'yen', ' ', 'mark'] }

        it 'joins consecutive operations of the same type across whitespaces' do
          expect(result).to eq([
                                 ['=', '&yen; is ', '&yen; is '],
                                 ['!', 'the yen symbol', 'a yen mark']
                               ])
        end
      end
    end

    context 'with different merge_threshold values' do
      let(:old_tokens) { ['The', ' ', 'quick', ' ', 'fox', ' ', 'jumped'] }
      let(:new_tokens) { ['The', ' ', 'slow', ' ', 'fox', ' ', 'hopped'] }

      context 'with default merge_threshold' do
        let(:result) { described_class.diff(old_tokens, new_tokens) }

        it 'merges fox token into changes' do
          expect(result).to eq([
                                 ['=', 'The ', 'The '],
                                 ['!', 'quick fox jumped', 'slow fox hopped']
                               ])
        end
      end

      context 'with merge_threshold 0' do
        let(:result) { described_class.diff(old_tokens, new_tokens, merge_threshold: 0) }

        it 'only merges whitespace' do
          expect(result).to eq([
                                 ['=', 'The ', 'The '],
                                 ['!', 'quick', 'slow'],
                                 ['=', ' fox ', ' fox '],
                                 ['!', 'jumped', 'hopped']
                               ])
        end
      end

      context 'with merge_threshold -1' do
        let(:result) { described_class.diff(old_tokens, new_tokens, merge_threshold: -1) }

        it 'disables merging entirely' do
          expect(result).to eq([
                                 ['=', 'The ', 'The '],
                                 ['!', 'quick', 'slow'],
                                 ['=', ' fox ', ' fox '],
                                 ['!', 'jumped', 'hopped']
                               ])
        end
      end

      context 'with merge_threshold false' do
        let(:result) { described_class.diff(old_tokens, new_tokens, merge_threshold: false) }

        it 'disables merging' do
          expect(result).to eq([
                                 ['=', 'The ', 'The '],
                                 ['!', 'quick', 'slow'],
                                 ['=', ' fox ', ' fox '],
                                 ['!', 'jumped', 'hopped']
                               ])
        end
      end
    end
  end

  describe '.mergeable_op?' do
    it 'returns false when merge_threshold is nil' do
      expect(described_class.send(:mergeable_op?, 'test', nil)).to be false
    end

    it 'returns false when merge_threshold is negative' do
      expect(described_class.send(:mergeable_op?, 'test', -1)).to be false
    end

    it 'returns true for whitespace when merge_threshold is 0' do
      expect(described_class.send(:mergeable_op?, '   ', 0)).to be true
      expect(described_class.send(:mergeable_op?, "\t \n", 0)).to be true
    end

    it 'returns false for non-whitespace when merge_threshold is 0' do
      expect(described_class.send(:mergeable_op?, 'test', 0)).to be false
    end

    it 'returns true when string length <= merge_threshold' do
      expect(described_class.send(:mergeable_op?, 'abc', 3)).to be true
      expect(described_class.send(:mergeable_op?, 'abcd', 3)).to be false
    end

    it 'returns true for whitespace regardless of length' do
      expect(described_class.send(:mergeable_op?, '       ', 3)).to be true
    end
  end

  describe '.finalize_op' do
    it 'returns add action when old_val is empty' do
      expect(described_class.send(:finalize_op, '!', '', 'new')).to eq(['+', nil, 'new'])
    end

    it 'returns delete action when new_val is empty' do
      expect(described_class.send(:finalize_op, '!', 'old', '')).to eq(['-', 'old', nil])
    end

    it 'preserves action and values when both present' do
      expect(described_class.send(:finalize_op, '!', 'old', 'new')).to eq(['!', 'old', 'new'])
    end
  end

  describe '.lcs_sdiff' do
    it 'delegates to Diff::LCS.sdiff' do
      old_tokens = %w[a b c]
      new_tokens = %w[a d c]
      result = described_class.send(:lcs_sdiff, old_tokens, new_tokens)
      expect(result.all?(Diff::LCS::Change)).to be true
      expect(result.map(&:to_a)).to eq([['=', [0, 'a'], [0, 'a']], ['!', [1, 'b'], [1, 'd']], ['=', [2, 'c'], [2, 'c']]])
    end
  end
end
