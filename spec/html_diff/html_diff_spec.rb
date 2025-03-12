# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTMLDiff do
  let(:html_format) { { class_insert: 'diffins', class_delete: 'diffdel', class_replace: 'diffmod' } }
  let(:options) { { html_format: html_format }.compact }
  let(:result) { described_class.diff(old_text, new_text, **options) }

  context 'when diffing basic text' do
    let(:old_text) { 'a word is here' }
    let(:new_text) { 'a nother word is there' }

    it 'diffs text correctly' do
      expect(result).to eq('a <ins class="diffins">nother </ins>word is <del class="diffmod">here</del><ins class="diffmod">there</ins>')
    end
  end

  context 'when inserting text' do
    let(:old_text) { 'a c' }
    let(:new_text) { 'a b c' }

    it 'inserts a letter and a space' do
      expect(result).to eq('a <ins class="diffins">b </ins>c')
    end
  end

  context 'when removing text' do
    let(:old_text) { 'a b c' }
    let(:new_text) { 'a c' }

    it 'removes a letter and a space' do
      expect(result).to eq('a <del class="diffdel">b </del>c')
    end
  end

  context 'when changing text' do
    let(:old_text) { 'a b c' }
    let(:new_text) { 'a d c' }

    it 'changes a letter' do
      expect(result).to eq('a <del class="diffmod">b</del><ins class="diffmod">d</ins> c')
    end
  end

  context 'when diffing accented characters' do
    let(:old_text) { 'blåbær dèjá vu' }
    let(:new_text) { 'blåbær deja vu' }

    it 'supports accents' do
      expect(result).to eq('blåbær <del class="diffmod">dèjá</del><ins class="diffmod">deja</ins> vu')
    end
  end

  context 'when diffing email addresses' do
    let(:old_text) { 'I sent an email to foo@bar.com!' }
    let(:new_text) { 'I sent an email to baz@bar.com!' }

    it 'supports email addresses' do
      expect(result).to eq('I sent an email to <del class="diffmod">foo@bar.com</del><ins class="diffmod">baz@bar.com</ins>!')
    end
  end

  context 'when diffing sentences with punctuation' do
    let(:old_text) { 'The quick red fox? "jumped" over; the "lazy", brown dog! Didn\'t he?' }
    let(:new_text) { 'The quick blue fox? \'hopped\' over! the "active", purple dog! Did he not?' }

    it 'supports sentences' do
      expect(result).to eq("The quick <del class=\"diffmod\">red</del><ins class=\"diffmod\">blue</ins> fox? <del class=\"diffmod\">\"jumped\" over;</del><ins class=\"diffmod\">'hopped' over!</ins> the \"<del class=\"diffmod\">lazy\", brown</del><ins class=\"diffmod\">active\", purple</ins> dog! <del class=\"diffmod\">Didn't he</del><ins class=\"diffmod\">Did he not</ins>?")
    end
  end

  context 'when diffing escaped HTML' do
    let(:old_text) { '&lt;div&gt;this &lt;span tag=1 class="foo"&gt;is a sentence&lt;/span&gt; test&lt;/div&gt;' }
    let(:new_text) { '&lt;div&gt;this &lt;span class="bar" tag=2&gt;is a string&lt;/label&gt; also a test&lt;/label&gt;' }

    it 'supports escaped HTML' do
      expect(result).to eq('&lt;div&gt;this &lt;span <del class="diffdel">tag=1 </del>class="<del class="diffmod">foo"</del><ins class="diffmod">bar" tag=2</ins>&gt;is a <del class="diffmod">sentence&lt;/span&gt; </del><ins class="diffmod">string&lt;/label&gt; also a </ins>test&lt;/<del class="diffmod">div</del><ins class="diffmod">label</ins>&gt;')
    end
  end

  context 'when diffing with image tags' do
    context 'with insertion' do
      let(:old_text) { 'a b c' }
      let(:new_text) { 'a b <img src="some_url" /> c' }

      it 'supports img tags insertion' do
        expect(result).to eq('a b <ins class="diffins"><img src="some_url" /> </ins>c')
      end
    end

    context 'with deletion' do
      let(:old_text) { 'a b <img src="some_url" /> c' }
      let(:new_text) { 'a b c' }

      it 'supports img tags deletion' do
        expect(result).to eq('a b <del class="diffdel"><img src="some_url" /> </del>c')
      end
    end
  end

  describe 'multi-language support' do
    context 'when diffing Cyrillic' do
      let(:old_text) { 'Привет, как дела?' }
      let(:new_text) { 'Привет, хорошо дела!' }

      it 'supports Cyrillic' do
        expect(result).to eq('Привет, <del class="diffmod">как дела?</del><ins class="diffmod">хорошо дела!</ins>')
      end
    end

    context 'when diffing Greek' do
      let(:old_text) { 'Καλημέρα κόσμε' }
      let(:new_text) { 'Καλησπέρα κόσμε' }

      it 'supports Greek' do
        expect(result).to eq('<del class="diffmod">Καλημέρα</del><ins class="diffmod">Καλησπέρα</ins> κόσμε')
      end
    end

    context 'when diffing Arabic' do
      let(:old_text) { 'مرحبا بالعالم' }
      let(:new_text) { 'مرحبا جميل بالعالم' }

      it 'supports Arabic' do
        expect(result).to eq('مرحبا <ins class="diffins">جميل </ins>بالعالم')
      end
    end

    context 'when diffing Hebrew' do
      let(:old_text) { 'שלום עולם' }
      let(:new_text) { 'שלום עולם קטן' }

      it 'supports Hebrew' do
        expect(result).to eq('שלום עולם<ins class="diffins"> קטן</ins>')
      end
    end

    context 'when diffing Vietnamese' do
      let(:old_text) { 'Xin chào thế giới' }
      let(:new_text) { 'Xin chào thế giới mới' }

      it 'supports Vietnamese' do
        expect(result).to eq('Xin chào thế giới<ins class="diffins"> mới</ins>')
      end
    end

    context 'when diffing mixed scripts' do
      let(:old_text) { 'Hello مرحبا Привет' }
      let(:new_text) { 'Hello مرحبا جدا Привет' }

      it 'handles mixed scripts' do
        expect(result).to eq('Hello مرحبا <ins class="diffins">جدا </ins>Привет')
      end
    end

    context 'when diffing Cyrillic with HTML tags' do
      let(:old_text) { '<div>Текст в теге</div>' }
      let(:new_text) { '<div>Новый текст в теге</div>' }

      it 'supports Cyrillic with HTML tags' do
        expect(result).to eq('<div><del class="diffmod">Текст</del><ins class="diffmod">Новый текст</ins> в теге</div>')
      end
    end

    context 'when diffing Arabic with HTML tags' do
      let(:old_text) { '<span>النص في العلامة</span>' }
      let(:new_text) { '<span>النص الجديد في العلامة</span>' }

      it 'supports Arabic with HTML tags' do
        expect(result).to eq('<span>النص <ins class="diffins">الجديد </ins>في العلامة</span>')
      end
    end

    context 'when diffing complex Hebrew changes' do
      let(:old_text) { 'אני אוהב לתכנת בשפת רובי' }
      let(:new_text) { 'אני אוהב מאוד לתכנת בשפת פייתון' }

      it 'handles complex Hebrew changes' do
        expect(result).to eq('אני אוהב <ins class="diffins">מאוד </ins>לתכנת בשפת <del class="diffmod">רובי</del><ins class="diffmod">פייתון</ins>')
      end
    end

    context 'when diffing Vietnamese with diacritics' do
      let(:old_text) { 'Tôi yêu lập trình' }
      let(:new_text) { 'Tôi thích lập trình' }

      it 'supports Vietnamese diacritics' do
        expect(result).to eq('Tôi <del class="diffmod">yêu</del><ins class="diffmod">thích</ins> lập trình')
      end
    end

    context 'when diffing mixed languages with punctuation' do
      let(:old_text) { 'Hello, Привет! مرحبا. שלום' }
      let(:new_text) { 'Hello, Привет! مرحبا جدا. שלום עולם' }

      it 'handles mixed languages with punctuation' do
        expect(result).to eq('Hello, Привет! مرحبا<ins class="diffins"> جدا</ins>. שלום<ins class="diffins"> עולם</ins>')
      end
    end

    context 'when diffing Greek with formatting tags' do
      let(:old_text) { '<b>Γεια σας</b> κόσμε' }
      let(:new_text) { '<b>Γεια σου</b> κόσμε' }

      it 'supports Greek with formatting tags' do
        expect(result).to eq('<b>Γεια <del class="diffmod">σας</del><ins class="diffmod">σου</ins></b> κόσμε')
      end
    end

    context 'when diffing changes within Arabic words' do
      let(:old_text) { 'البرمجة ممتعة' }
      let(:new_text) { 'البرمجة سهلة' }

      it 'detects changes within Arabic words' do
        expect(result).to eq('البرمجة <del class="diffmod">ممتعة</del><ins class="diffmod">سهلة</ins>')
      end
    end

    context 'when diffing RTL text with HTML' do
      let(:old_text) { '<div dir="rtl">שלום עולם</div>' }
      let(:new_text) { '<div dir="rtl">שלום חבר</div>' }

      it 'properly handles RTL text with HTML' do
        expect(result).to eq('<div dir="rtl">שלום <del class="diffmod">עולם</del><ins class="diffmod">חבר</ins></div>')
      end
    end

    context 'when diffing multi-word changes in Vietnamese' do
      let(:old_text) { 'Tôi đang học Ruby' }
      let(:new_text) { 'Tôi đang học Python rất vui' }

      it 'handles multi-word changes in Vietnamese' do
        expect(result).to eq('Tôi đang học <del class="diffmod">Ruby</del><ins class="diffmod">Python rất vui</ins>')
      end
    end

    # Additional language tests...
    context 'when diffing Chinese' do
      let(:old_text) { '这个是中文内容, Ruby is the bast' }
      let(:new_text) { '这是中国语内容，Ruby is the best language.' }

      it 'supports Chinese' do
        expect(result).to eq('这<del class="diffdel">个是中文内容, </del>Ruby is the <del class="diffmod">bast</del><ins class="diffmod">best language.</ins>')
      end
    end

    context 'when diffing Hindi (Devanagari)' do
      let(:old_text) { 'नमस्ते दुनिया' }
      let(:new_text) { 'नमस्ते प्यारी दुनिया' }

      it 'supports Hindi (Devanagari)' do
        expect(result).to eq('नमस्ते <ins class="diffins">प्यारी </ins>दुनिया')
      end
    end

    context 'when diffing Thai' do
      let(:old_text) { 'สวัสดีชาวโลก' }
      let(:new_text) { 'สวัสดีชาวโลกที่สวยงาม' }

      it 'supports Thai' do
        expect(result).to eq('สวัสดีชาวโลก<ins class="diffins">ที่สวยงาม</ins>')
      end
    end

    context 'when diffing Japanese' do
      let(:old_text) { 'こんにちは世界' }
      let(:new_text) { 'こんにちは美しい世界' }

      it 'supports Japanese' do
        expect(result).to eq('こんにちは<ins class="diffins">美しい</ins>世界')
      end
    end

    context 'when diffing Korean' do
      let(:old_text) { '안녕하세요 세계' }
      let(:new_text) { '안녕하세요 아름다운 세계' }

      it 'supports Korean' do
        expect(result).to eq('안녕하세요 <ins class="diffins">아름다운 </ins>세계')
      end
    end

    context 'when diffing Armenian' do
      let(:old_text) { 'Բարեւ աշխարհ' }
      let(:new_text) { 'Բարեւ գեղեցիկ աշխարհ' }

      it 'supports Armenian' do
        expect(result).to eq('Բարեւ <ins class="diffins">գեղեցիկ </ins>աշխարհ')
      end
    end

    context 'when diffing Georgian' do
      let(:old_text) { 'გამარჯობა მსოფლიო' }
      let(:new_text) { 'გამარჯობა ლამაზი მსოფლიო' }

      it 'supports Georgian' do
        expect(result).to eq('გამარჯობა <ins class="diffins">ლამაზი </ins>მსოფლიო')
      end
    end

    # Other languages continue in the same pattern...
    context 'when diffing Amharic' do
      let(:old_text) { 'ሰላም ዓለም' }
      let(:new_text) { 'ሰላም ውብ ዓለም' }

      it 'supports Amharic (Ethiopic)' do
        expect(result).to eq('ሰላም <ins class="diffins">ውብ </ins>ዓለም')
      end
    end

    context 'when diffing complex changes in Japanese' do
      let(:old_text) { '日本語は面白いです' }
      let(:new_text) { '日本語は素晴らしいです' }

      it 'handles complex changes in Japanese' do
        expect(result).to eq('日本語は<del class="diffmod">面白</del><ins class="diffmod">素晴らし</ins>いです')
      end
    end

    context 'when diffing changes within Devanagari words' do
      let(:old_text) { 'मैं प्रोग्रामिंग पसंद करता हूँ' }
      let(:new_text) { 'मैं कोडिंग पसंद करता हूँ' }

      it 'detects changes within Devanagari words' do
        expect(result).to eq('मैं <del class="diffmod">प्रोग्रामिंग</del><ins class="diffmod">कोडिंग</ins> पसंद करता हूँ')
      end
    end
  end

  describe 'HTML entities' do
    context 'when diffing basic HTML entities' do
      let(:old_text) { 'a &lt; b &gt; c' }
      let(:new_text) { 'a &lt; b &amp; c' }

      it 'supports basic HTML entities' do
        expect(result).to eq('a &lt; b <del class="diffmod">&gt;</del><ins class="diffmod">&amp;</ins> c')
      end
    end

    context 'when handling entity changes' do
      let(:old_text) { '&amp; &lt; &gt; &quot; &apos;' }
      let(:new_text) { '&amp; &lt; &gt; &apos; &quot;' }

      it 'handles entity changes' do
        expect(result).to eq('&amp; &lt; &gt; <del class="diffdel">&quot; </del>&apos;<ins class="diffins"> &quot;</ins>')
      end
    end

    context 'when preserving numeric HTML entities' do
      let(:old_text) { '&#8364; is euro' }
      let(:new_text) { '&#8364; is the euro symbol' }

      it 'preserves numeric HTML entities' do
        expect(result).to eq('&#8364; is <ins class="diffins">the </ins>euro<ins class="diffins"> symbol</ins>')
      end
    end

    context 'when diffing content with multiple entities' do
      let(:old_text) { '&lt;p&gt;text&lt;/p&gt;' }
      let(:new_text) { '&lt;p&gt;new text&lt;/p&gt;' }

      it 'diffs content with multiple entities correctly' do
        expect(result).to eq('&lt;p&gt;<ins class="diffins">new </ins>text&lt;/p&gt;')
      end
    end

    context 'when treating entities as single units' do
      let(:old_text) { 'a&nbsp;b' }
      let(:new_text) { 'a b' }

      it 'treats entities as single units' do
        expect(result).to eq('a<del class="diffmod">&nbsp;</del><ins class="diffmod"> </ins>b')
      end
    end

    context 'when handling mixed entities and normal text' do
      let(:old_text) { '&copy; 2023 Company' }
      let(:new_text) { '&copy; 2024 New Company' }

      it 'handles mixed entities and normal text' do
        expect(result).to eq('&copy; <del class="diffmod">2023</del><ins class="diffmod">2024 New</ins> Company')
      end
    end

    context 'when diffing escaped HTML tags' do
      let(:old_text) { '&lt;div class="old"&gt;content&lt;/div&gt;' }
      let(:new_text) { '&lt;div class="new"&gt;content&lt;/div&gt;' }

      it 'diffs escaped HTML tags correctly' do
        expect(result).to eq('&lt;div class="<del class="diffmod">old</del><ins class="diffmod">new</ins>"&gt;content&lt;/div&gt;')
      end
    end

    context 'when handling HTML entities in different scripts' do
      let(:old_text) { '&lt;span&gt;привет&lt;/span&gt;' }
      let(:new_text) { '&lt;span&gt;здравствуйте&lt;/span&gt;' }

      it 'handles HTML entities in different scripts' do
        expect(result).to eq('&lt;span&gt;<del class="diffmod">привет</del><ins class="diffmod">здравствуйте</ins>&lt;/span&gt;')
      end
    end

    context 'when processing HTML entities in attributes' do
      let(:old_text) { '&lt;a title="&amp; more"&gt;link&lt;/a&gt;' }
      let(:new_text) { '&lt;a title="&amp; less"&gt;link&lt;/a&gt;' }

      it 'correctly processes HTML entities in attributes' do
        expect(result).to eq('&lt;a title="&amp; <del class="diffmod">more</del><ins class="diffmod">less</ins>"&gt;link&lt;/a&gt;')
      end
    end

    context 'when handling complex entity sequences' do
      let(:old_text) { '&alpha;&beta;&gamma;' }
      let(:new_text) { '&alpha;&delta;&gamma;' }

      it 'handles complex entity sequences' do
        expect(result).to eq('&alpha;<del class="diffmod">&beta;</del><ins class="diffmod">&delta;</ins>&gamma;')
      end
    end
  end
end
