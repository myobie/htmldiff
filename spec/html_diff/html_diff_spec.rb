# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff do
  let(:html_format) { { class_replace: 'mod' } }
  let(:options) { { html_format: html_format }.compact }
  let(:result) { described_class.diff(old_text, new_text, **options) }

  describe '.diff' do
    context 'when diffing basic text' do
      let(:old_text) { 'a word is here' }
      let(:new_text) { 'a nother word is there' }

      it 'diffs text correctly' do
        expect(result).to eq('a <ins>nother </ins>word is <del class="mod">here</del><ins class="mod">there</ins>')
      end
    end

    context 'when diffing basic text 2' do
      let(:old_text) { 'a word now is here' }
      let(:new_text) { 'a second word is there' }

      it 'diffs text correctly' do
        expect(result).to eq('a <ins>second </ins>word <del class="mod">now is here</del><ins class="mod">is there</ins>')
      end
    end

    context 'when inserting text' do
      let(:old_text) { 'a c' }
      let(:new_text) { 'a b c' }

      it 'inserts a letter and a space' do
        expect(result).to eq('a <ins>b </ins>c')
      end
    end

    context 'when removing text' do
      let(:old_text) { 'a b c' }
      let(:new_text) { 'a c' }

      it 'removes a letter and a space' do
        expect(result).to eq('a <del>b </del>c')
      end
    end

    context 'when changing text' do
      let(:old_text) { 'a b c' }
      let(:new_text) { 'a d c' }

      it 'changes a letter' do
        expect(result).to eq('a <del class="mod">b</del><ins class="mod">d</ins> c')
      end
    end

    context 'when diffing accented characters' do
      let(:old_text) { 'blåbær dèjá vu' }
      let(:new_text) { 'blåbær deja vu' }

      it 'supports accents' do
        expect(result).to eq('blåbær <del class="mod">dèjá</del><ins class="mod">deja</ins> vu')
      end
    end

    context 'when diffing email addresses' do
      let(:old_text) { 'I sent an email to foo@bar.com!' }
      let(:new_text) { 'I sent an email to baz@bar.com!' }

      it 'supports email addresses' do
        expect(result).to eq('I sent an email to <del class="mod">foo@bar.com</del><ins class="mod">baz@bar.com</ins>!')
      end
    end

    context 'when diffing sentences with punctuation' do
      let(:old_text) { 'The quick red fox? "jumped" over; the "lazy", brown dog! Didn\'t he?' }
      let(:new_text) { 'The quick blue fox? \'hopped\' over! the "active", purple dog! Did he not?' }

      it 'supports sentences' do
        expect(result).to eq("The quick <del class=\"mod\">red</del><ins class=\"mod\">blue</ins> fox? <del class=\"mod\">\"jumped\" over;</del><ins class=\"mod\">'hopped' over!</ins> the \"<del class=\"mod\">lazy\", brown</del><ins class=\"mod\">active\", purple</ins> dog! <del class=\"mod\">Didn't he</del><ins class=\"mod\">Did he not</ins>?")
      end
    end

    context 'when diffing escaped HTML' do
      let(:old_text) { '&lt;div&gt;this &lt;span tag=1 class="foo"&gt;is a sentence&lt;/span&gt; test&lt;/div&gt;' }
      let(:new_text) { '&lt;div&gt;this &lt;span class="bar" tag=2&gt;is a string&lt;/label&gt; also a test&lt;/label&gt;' }

      it 'supports escaped HTML' do
        expect(result).to eq('&lt;div&gt;this &lt;span <del>tag=1 </del>class="<del class="mod">foo"</del><ins class="mod">bar" tag=2</ins>&gt;is a <del class="mod">sentence&lt;/span&gt; </del><ins class="mod">string&lt;/label&gt; also a </ins>test&lt;/<del class="mod">div</del><ins class="mod">label</ins>&gt;')
      end
    end

    context 'when diffing with image tags' do
      context 'with insertion' do
        let(:old_text) { 'a b c' }
        let(:new_text) { 'a b <img src="some_url" /> c' }

        it 'supports img tags insertion' do
          expect(result).to eq('a b <ins><img src="some_url" /> </ins>c')
        end
      end

      context 'with deletion' do
        let(:old_text) { 'a b <img src="some_url" /> c' }
        let(:new_text) { 'a b c' }

        it 'supports img tags deletion' do
          expect(result).to eq('a b <del><img src="some_url" /> </del>c')
        end
      end
    end

    context 'with custom tokenizer' do
      let(:custom_tokenizer) do
        Module.new do
          def self.tokenize(string)
            string.chars
          end
        end
      end

      let(:old_text) { 'abc' }
      let(:new_text) { 'abd' }
      let(:options) { { tokenizer: custom_tokenizer } }

      it 'uses the custom tokenizer' do
        expect(result).to eq('ab<del>c</del><ins>d</ins>')
      end
    end

    context 'with custom formatter' do
      let(:custom_formatter) do
        Module.new do
          def self.format(changes)
            changes.map do |action, old_string, new_string|
              case action
              when '='
                new_string
              when '-'
                "[REMOVED:#{old_string}]"
              when '+'
                "[ADDED:#{new_string}]"
              when '!'
                "[CHANGED:#{old_string}->#{new_string}]"
              end
            end.join
          end
        end
      end

      let(:old_text) { 'a word is here' }
      let(:new_text) { 'a nother word is there' }
      let(:options) { { formatter: custom_formatter } }

      it 'uses the custom formatter' do
        expect(result).to eq('a [ADDED:nother ]word is [CHANGED:here->there]')
      end
    end

    context 'with merge_threshold parameter' do
      let(:old_text) { 'The quick fox jumped over the dog.' }
      let(:new_text) { 'The slow fox hopped over the dog.' }

      context 'with default merge_threshold' do
        let(:options) { {} }

        it 'merges word "fox" into changes' do
          expect(result).to eq('The <del>quick fox jumped</del><ins>slow fox hopped</ins> over the dog.')
        end
      end

      context 'with merge_threshold set to 0' do
        let(:options) { { merge_threshold: 0 } }

        it 'only merges whitespace' do
          expect(result).to eq('The <del>quick</del><ins>slow</ins> fox <del>jumped</del><ins>hopped</ins> over the dog.')
        end

        context 'with whitespace between changes' do
          let(:old_text) { 'The quick red fox.' }
          let(:new_text) { 'The slow brown fox.' }

          it 'merges whitespace' do
            expect(result).to eq('The <del>quick red</del><ins>slow brown</ins> fox.')
          end
        end
      end

      shared_examples_for 'disables merging entirely' do
        it 'disables merging entirely' do
          expect(result).to eq('The <del>quick</del><ins>slow</ins> fox <del>jumped</del><ins>hopped</ins> over the dog.')
        end

        context 'with whitespace between changes' do
          let(:old_text) { 'The quick red fox.' }
          let(:new_text) { 'The slow brown fox.' }

          it 'disables merging entirely' do
            expect(result).to eq('The <del>quick</del><ins>slow</ins> <del>red</del><ins>brown</ins> fox.')
          end
        end
      end

      context 'with merge_threshold set to -1' do
        let(:options) { { merge_threshold: -1 } }

        it_behaves_like 'disables merging entirely'
      end

      context 'with merge_threshold set to false' do
        let(:options) { { merge_threshold: false } }

        it_behaves_like 'disables merging entirely'
      end
    end

    context 'with nil inputs' do
      context 'with nil old_text' do
        let(:old_text) { nil }
        let(:new_text) { 'some text' }

        it 'handles nil old_text' do
          expect(result).to eq('<ins>some text</ins>')
        end
      end

      context 'with nil new_text' do
        let(:old_text) { 'some text' }
        let(:new_text) { nil }

        it 'handles nil new_text' do
          expect(result).to eq('<del>some text</del>')
        end
      end

      context 'with both nil' do
        let(:old_text) { nil }
        let(:new_text) { nil }

        it 'handles nil new_text' do
          expect(result).to eq('')
        end
      end

      context 'with empty strings' do
        let(:old_text) { '' }
        let(:new_text) { '' }

        it 'returns empty string for empty inputs' do
          expect(result).to eq('')
        end
      end
    end

    describe 'multi-language support' do
      context 'when diffing Cyrillic' do
        let(:old_text) { 'Привет, как дела?' }
        let(:new_text) { 'Привет, хорошо дела!' }

        it 'supports Cyrillic' do
          expect(result).to eq('Привет, <del class="mod">как дела?</del><ins class="mod">хорошо дела!</ins>')
        end
      end

      context 'when diffing Greek' do
        let(:old_text) { 'Καλημέρα κόσμε' }
        let(:new_text) { 'Καλησπέρα κόσμε' }

        it 'supports Greek' do
          expect(result).to eq('<del class="mod">Καλημέρα</del><ins class="mod">Καλησπέρα</ins> κόσμε')
        end
      end

      context 'when diffing Arabic' do
        let(:old_text) { 'مرحبا بالعالم' }
        let(:new_text) { 'مرحبا جميل بالعالم' }

        it 'supports Arabic' do
          expect(result).to eq('مرحبا <ins>جميل </ins>بالعالم')
        end
      end

      context 'when diffing Hebrew' do
        let(:old_text) { 'שלום עולם' }
        let(:new_text) { 'שלום עולם קטן' }

        it 'supports Hebrew' do
          expect(result).to eq('שלום עולם<ins> קטן</ins>')
        end
      end

      context 'when diffing Vietnamese' do
        let(:old_text) { 'Xin chào thế giới' }
        let(:new_text) { 'Xin chào thế giới mới' }

        it 'supports Vietnamese' do
          expect(result).to eq('Xin chào thế giới<ins> mới</ins>')
        end
      end

      context 'when diffing mixed scripts' do
        let(:old_text) { 'Hello مرحبا Привет' }
        let(:new_text) { 'Hello مرحبا جدا Привет' }

        it 'handles mixed scripts' do
          expect(result).to eq('Hello مرحبا <ins>جدا </ins>Привет')
        end
      end

      context 'when diffing Cyrillic with HTML tags' do
        let(:old_text) { '<div>Текст в теге</div>' }
        let(:new_text) { '<div>Новый текст в теге</div>' }

        it 'supports Cyrillic with HTML tags' do
          expect(result).to eq('<div><del class="mod">Текст</del><ins class="mod">Новый текст</ins> в теге</div>')
        end
      end

      context 'when diffing Arabic with HTML tags' do
        let(:old_text) { '<span>النص في العلامة</span>' }
        let(:new_text) { '<span>النص الجديد في العلامة</span>' }

        it 'supports Arabic with HTML tags' do
          expect(result).to eq('<span>النص <ins>الجديد </ins>في العلامة</span>')
        end
      end

      context 'when diffing complex Hebrew changes' do
        let(:old_text) { 'אני אוהב לתכנת בשפת רובי' }
        let(:new_text) { 'אני אוהב מאוד לתכנת בשפת פייתון' }

        it 'handles complex Hebrew changes' do
          expect(result).to eq('אני אוהב <ins>מאוד </ins>לתכנת בשפת <del class="mod">רובי</del><ins class="mod">פייתון</ins>')
        end
      end

      context 'when diffing Vietnamese with diacritics' do
        let(:old_text) { 'Tôi yêu lập trình' }
        let(:new_text) { 'Tôi thích lập trình' }

        it 'supports Vietnamese diacritics' do
          expect(result).to eq('Tôi <del class="mod">yêu</del><ins class="mod">thích</ins> lập trình')
        end
      end

      context 'when diffing mixed languages with punctuation' do
        let(:old_text) { 'Hello, Привет! مرحبا. שלום' }
        let(:new_text) { 'Hello, Привет! مرحبا جدا. שלום עולם' }

        it 'handles mixed languages with punctuation' do
          expect(result).to eq('Hello, Привет! مرحبا<ins> جدا</ins>. שלום<ins> עולם</ins>')
        end
      end

      context 'when diffing Greek with formatting tags' do
        let(:old_text) { '<b>Γεια σας</b> κόσμε' }
        let(:new_text) { '<b>Γεια σου</b> κόσμε' }

        it 'supports Greek with formatting tags' do
          expect(result).to eq('<b>Γεια <del class="mod">σας</del><ins class="mod">σου</ins></b> κόσμε')
        end
      end

      context 'when diffing changes within Arabic words' do
        let(:old_text) { 'البرمجة ممتعة' }
        let(:new_text) { 'البرمجة سهلة' }

        it 'detects changes within Arabic words' do
          expect(result).to eq('البرمجة <del class="mod">ممتعة</del><ins class="mod">سهلة</ins>')
        end
      end

      context 'when diffing RTL text with HTML' do
        let(:old_text) { '<div dir="rtl">שלום עולם</div>' }
        let(:new_text) { '<div dir="rtl">שלום חבר</div>' }

        it 'properly handles RTL text with HTML' do
          expect(result).to eq('<div dir="rtl">שלום <del class="mod">עולם</del><ins class="mod">חבר</ins></div>')
        end
      end

      context 'when diffing multi-word changes in Vietnamese' do
        let(:old_text) { 'Tôi đang học Ruby' }
        let(:new_text) { 'Tôi đang học Python rất vui' }

        it 'handles multi-word changes in Vietnamese' do
          expect(result).to eq('Tôi đang học <del class="mod">Ruby</del><ins class="mod">Python rất vui</ins>')
        end
      end

      context 'when diffing Chinese' do
        let(:old_text) { '这个是中文内容, Ruby is the bast' }
        let(:new_text) { '这是中国语内容，Ruby is the best language.' }

        it 'supports Chinese' do
          expect(result).to eq('这<del class="mod">个是中文内容, </del><ins class="mod">是中国语内容，</ins>Ruby is the <del class="mod">bast</del><ins class="mod">best language.</ins>')
        end
      end

      context 'when diffing Hindi (Devanagari)' do
        let(:old_text) { 'नमस्ते दुनिया' }
        let(:new_text) { 'नमस्ते प्यारी दुनिया' }

        it 'supports Hindi (Devanagari)' do
          expect(result).to eq('नमस्ते <ins>प्यारी </ins>दुनिया')
        end
      end

      context 'when diffing Thai' do
        let(:old_text) { 'สวัสดีชาวโลก' }
        let(:new_text) { 'สวัสดีชาวโลกที่สวยงาม' }

        it 'supports Thai' do
          expect(result).to eq('สวัสดีชาวโลก<ins>ที่สวยงาม</ins>')
        end
      end

      context 'when diffing Japanese' do
        let(:old_text) { 'こんにちは世界' }
        let(:new_text) { 'こんにちは美しい世界' }

        it 'supports Japanese' do
          expect(result).to eq('こんにちは<ins>美しい</ins>世界')
        end
      end

      context 'when diffing Korean' do
        let(:old_text) { '안녕하세요 세계' }
        let(:new_text) { '안녕하세요 아름다운 세계' }

        it 'supports Korean' do
          expect(result).to eq('안녕하세요 <ins>아름다운 </ins>세계')
        end
      end

      context 'when diffing Armenian' do
        let(:old_text) { 'Բարեւ աշխարհ' }
        let(:new_text) { 'Բարեւ գեղեցիկ աշխարհ' }

        it 'supports Armenian' do
          expect(result).to eq('Բարեւ <ins>գեղեցիկ </ins>աշխարհ')
        end
      end

      context 'when diffing Georgian' do
        let(:old_text) { 'გამარჯობა მსოფლიო' }
        let(:new_text) { 'გამარჯობა ლამაზი მსოფლიო' }

        it 'supports Georgian' do
          expect(result).to eq('გამარჯობა <ins>ლამაზი </ins>მსოფლიო')
        end
      end

      context 'when diffing Amharic' do
        let(:old_text) { 'ሰላም ዓለም' }
        let(:new_text) { 'ሰላም ውብ ዓለም' }

        it 'supports Amharic (Ethiopic)' do
          expect(result).to eq('ሰላም <ins>ውብ </ins>ዓለም')
        end
      end

      context 'when diffing complex changes in Japanese' do
        let(:old_text) { '日本語は面白いです' }
        let(:new_text) { '日本語は素晴らしいです' }

        it 'handles complex changes in Japanese' do
          expect(result).to eq('日本語は<del class="mod">面白</del><ins class="mod">素晴らし</ins>いです')
        end
      end

      context 'when diffing changes within Devanagari words' do
        let(:old_text) { 'मैं प्रोग्रामिंग पसंद करता हूँ' }
        let(:new_text) { 'मैं कोडिंग पसंद करता हूँ' }

        it 'detects changes within Devanagari words' do
          expect(result).to eq('मैं <del class="mod">प्रोग्रामिंग</del><ins class="mod">कोडिंग</ins> पसंद करता हूँ')
        end
      end
    end

    describe 'HTML entities' do
      context 'when diffing basic HTML entities' do
        let(:old_text) { 'a &lt; b &gt; c' }
        let(:new_text) { 'a &lt; b &amp; c' }

        it 'supports basic HTML entities' do
          expect(result).to eq('a &lt; b <del class="mod">&gt;</del><ins class="mod">&amp;</ins> c')
        end
      end

      context 'when handling entity changes' do
        let(:old_text) { '&amp; &lt; &gt; &quot; &apos;' }
        let(:new_text) { '&amp; &lt; &gt; &apos; &quot;' }

        it 'handles entity changes' do
          expect(result).to eq('&amp; &lt; &gt; <del>&quot; </del>&apos;<ins> &quot;</ins>')
        end
      end

      context 'when preserving numeric HTML entities' do
        let(:old_text) { '&#8364; is euro' }
        let(:new_text) { '&#8364; is the euro symbol' }

        it 'preserves numeric HTML entities' do
          expect(result).to eq('&#8364; is <ins>the </ins>euro<ins> symbol</ins>')
        end
      end

      context 'when diffing content with multiple entities' do
        let(:old_text) { '&lt;p&gt;text&lt;/p&gt;' }
        let(:new_text) { '&lt;p&gt;new text&lt;/p&gt;' }

        it 'diffs content with multiple entities correctly' do
          expect(result).to eq('&lt;p&gt;<ins>new </ins>text&lt;/p&gt;')
        end
      end

      context 'when treating entities as single units' do
        let(:old_text) { 'a&nbsp;b' }
        let(:new_text) { 'a b' }

        it 'treats entities as single units' do
          expect(result).to eq('a<del class="mod">&nbsp;</del><ins class="mod"> </ins>b')
        end
      end

      context 'when handling mixed entities and normal text' do
        let(:old_text) { '&copy; 2023 Company' }
        let(:new_text) { '&copy; 2024 New Company' }

        it 'handles mixed entities and normal text' do
          expect(result).to eq('&copy; <del class="mod">2023</del><ins class="mod">2024 New</ins> Company')
        end
      end

      context 'when diffing escaped HTML tags' do
        let(:old_text) { '&lt;div class="old"&gt;content&lt;/div&gt;' }
        let(:new_text) { '&lt;div class="new"&gt;content&lt;/div&gt;' }

        it 'diffs escaped HTML tags correctly' do
          expect(result).to eq('&lt;div class="<del class="mod">old</del><ins class="mod">new</ins>"&gt;content&lt;/div&gt;')
        end
      end

      context 'when handling HTML entities in different scripts' do
        let(:old_text) { '&lt;span&gt;привет&lt;/span&gt;' }
        let(:new_text) { '&lt;span&gt;здравствуйте&lt;/span&gt;' }

        it 'handles HTML entities in different scripts' do
          expect(result).to eq('&lt;span&gt;<del class="mod">привет</del><ins class="mod">здравствуйте</ins>&lt;/span&gt;')
        end
      end

      context 'when processing HTML entities in attributes' do
        let(:old_text) { '&lt;a title="&amp; more"&gt;link&lt;/a&gt;' }
        let(:new_text) { '&lt;a title="&amp; less"&gt;link&lt;/a&gt;' }

        it 'correctly processes HTML entities in attributes' do
          expect(result).to eq('&lt;a title="&amp; <del class="mod">more</del><ins class="mod">less</ins>"&gt;link&lt;/a&gt;')
        end
      end

      context 'when handling complex entity sequences' do
        let(:old_text) { '&alpha;&beta;&gamma;' }
        let(:new_text) { '&alpha;&delta;&gamma;' }

        it 'handles complex entity sequences' do
          expect(result).to eq('&alpha;<del class="mod">&beta;</del><ins class="mod">&delta;</ins>&gamma;')
        end
      end
    end
  end
end
