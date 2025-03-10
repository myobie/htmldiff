# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe HTMLDiff do
  it "should diff text" do
    diff = described_class.diff('a word is here', 'a nother word is there')
    expect(diff).to eq("a<ins class=\"diffins\"> nother</ins> word is <del class=\"diffmod\">here</del><ins class=\"diffmod\">there</ins>")
  end

  it "should insert a letter and a space" do
    diff = described_class.diff('a c', 'a b c')
    expect(diff).to eq("a <ins class=\"diffins\">b </ins>c")
  end

  it "should remove a letter and a space" do
    diff = described_class.diff('a b c', 'a c')
    expect(diff).to eq("a <del class=\"diffdel\">b </del>c")
  end

  it "should change a letter" do
    diff = described_class.diff('a b c', 'a d c')
    expect(diff).to eq("a <del class=\"diffmod\">b</del><ins class=\"diffmod\">d</ins> c")
  end

  it "should support accents" do
    diff = described_class.diff('blåbær dèjá vu', 'blåbær deja vu')
    expect(diff).to eq("blåbær <del class=\"diffmod\">dèjá</del><ins class=\"diffmod\">deja</ins> vu")
  end

  it "should support email addresses" do
    diff = described_class.diff('I sent an email to foo@bar.com!',
                                'I sent an email to baz@bar.com!',)
    expect(diff).to eq("I sent an email to <del class=\"diffmod\">foo@bar.com</del><ins class=\"diffmod\">baz@bar.com</ins>!")
  end

  it "should support sentences" do
    diff = described_class.diff('The quick red fox? "jumped" over; the "lazy", brown dog! Didn\'t he?',
                                'The quick blue fox? \'hopped\' over! the "active", purple dog! Did he not?')
    expect(diff).to eq("The quick <del class=\"diffmod\">red</del><ins class=\"diffmod\">blue</ins> fox? <del class=\"diffmod\">\"jumped\"</del><ins class=\"diffmod\">'hopped'</ins> over<del class=\"diffmod\">;</del><ins class=\"diffmod\">!</ins> the \"<del class=\"diffmod\">lazy</del><ins class=\"diffmod\">active</ins>\", <del class=\"diffmod\">brown</del><ins class=\"diffmod\">purple</ins> dog! <del class=\"diffmod\">Didn't</del><ins class=\"diffmod\">Did</ins> he<ins class=\"diffins\"> not</ins>?")
  end

  it "should support escaped HTML" do
    diff = described_class.diff('&lt;div&gt;this &lt;span tag=1 class="foo"&gt;is a sentence&lt;/span&gt; test&lt;/div&gt;',
                                '&lt;div&gt;this &lt;span class="bar" tag=2&gt;is a string&lt;/label&gt; also a test&lt;/label&gt;')
    expect(diff).to eq("&lt;div&gt;this &lt;span <del class=\"diffdel\">tag=1 </del>class=\"<del class=\"diffmod\">foo</del><ins class=\"diffmod\">bar</ins>\"<ins class=\"diffins\"> tag=2</ins>&gt;is a <del class=\"diffmod\">sentence</del><ins class=\"diffmod\">string</ins>&lt;/<del class=\"diffmod\">span</del><ins class=\"diffmod\">label</ins>&gt;<ins class=\"diffins\"> also a</ins> test&lt;/<del class=\"diffmod\">div</del><ins class=\"diffmod\">label</ins>&gt;")
  end

  it "should support img tags insertion" do
    oldv = 'a b c'
    newv = 'a b <img src="some_url" /> c'
    diff = described_class.diff(oldv, newv)
    expect(diff).to eq("a b <ins class=\"diffins\"><img src=\"some_url\" /> </ins>c")
  end

  it "should support img tags deletion" do
    oldv = 'a b c'
    newv = 'a b <img src="some_url" /> c'
    diff = described_class.diff(newv, oldv)
    expect(diff).to eq("a b <del class=\"diffdel\"><img src=\"some_url\" /> </del>c")
  end

  describe "multi-language support" do
    it "should support Cyrillic" do
      diff = described_class.diff('Привет, как дела?', 'Привет, хорошо дела!')
      expect(diff).to eq("Привет, <del class=\"diffmod\">как</del><ins class=\"diffmod\">хорошо</ins> дела<del class=\"diffmod\">?</del><ins class=\"diffmod\">!</ins>")
    end

    it "should support Greek" do
      diff = described_class.diff('Καλημέρα κόσμε', 'Καλησπέρα κόσμε')
      expect(diff).to eq("<del class=\"diffmod\">Καλημέρα</del><ins class=\"diffmod\">Καλησπέρα</ins> κόσμε")
    end

    it "should support Arabic" do
      diff = described_class.diff('مرحبا بالعالم', 'مرحبا جميل بالعالم')
      expect(diff).to eq("مرحبا <ins class=\"diffins\">جميل </ins>بالعالم")
    end

    it "should support Hebrew" do
      diff = described_class.diff('שלום עולם', 'שלום עולם קטן')
      expect(diff).to eq("שלום עולם<ins class=\"diffins\"> קטן</ins>")
    end

    it "should support Vietnamese" do
      diff = described_class.diff('Xin chào thế giới', 'Xin chào thế giới mới')
      expect(diff).to eq("Xin chào thế giới<ins class=\"diffins\"> mới</ins>")
    end

    it "should handle mixed scripts" do
      diff = described_class.diff('Hello مرحبا Привет', 'Hello مرحبا جدا Привет')
      expect(diff).to eq("Hello مرحبا <ins class=\"diffins\">جدا </ins>Привет")
    end

    it "should support Cyrillic with HTML tags" do
      diff = described_class.diff('<div>Текст в теге</div>', '<div>Новый текст в теге</div>')
      expect(diff).to eq("<div><del class=\"diffmod\">Текст</del><ins class=\"diffmod\">Новый текст</ins> в теге</div>")
    end

    it "should support Arabic with HTML tags" do
      diff = described_class.diff('<span>النص في العلامة</span>', '<span>النص الجديد في العلامة</span>')
      expect(diff).to eq("<span>النص<ins class=\"diffins\"> الجديد</ins> في العلامة</span>")
    end

    it "should handle complex Hebrew changes" do
      diff = described_class.diff('אני אוהב לתכנת בשפת רובי', 'אני אוהב מאוד לתכנת בשפת פייתון')
      expect(diff).to eq("אני אוהב<ins class=\"diffins\"> מאוד</ins> לתכנת בשפת <del class=\"diffmod\">רובי</del><ins class=\"diffmod\">פייתון</ins>")
    end

    it "should support Vietnamese diacritics" do
      diff = described_class.diff('Tôi yêu lập trình', 'Tôi thích lập trình')
      expect(diff).to eq("Tôi <del class=\"diffmod\">yêu</del><ins class=\"diffmod\">thích</ins> lập trình")
    end

    pending "should handle mixed languages with punctuation" do
      diff = described_class.diff('Hello, Привет! مرحبا. שלום', 'Hello, Привет! مرحبا جدا. שלום עולם')
      expect(diff).to eq("Hello, Привет! <del class=\"diffmod\">مرحبا.</del><ins class=\"diffmod\">مرحبا جدا.</ins> שלום<ins class=\"diffins\"> עולם</ins>")
    end

    it "should support Greek with formatting tags" do
      diff = described_class.diff('<b>Γεια σας</b> κόσμε', '<b>Γεια σου</b> κόσμε')
      expect(diff).to eq("<b>Γεια <del class=\"diffmod\">σας</del><ins class=\"diffmod\">σου</ins></b> κόσμε")
    end

    it "should detect changes within Arabic words" do
      diff = described_class.diff('البرمجة ممتعة', 'البرمجة سهلة')
      expect(diff).to eq("البرمجة <del class=\"diffmod\">ممتعة</del><ins class=\"diffmod\">سهلة</ins>")
    end

    it "should properly handle RTL text with HTML" do
      diff = described_class.diff('<div dir="rtl">שלום עולם</div>', '<div dir="rtl">שלום חבר</div>')
      expect(diff).to eq("<div dir=\"rtl\">שלום <del class=\"diffmod\">עולם</del><ins class=\"diffmod\">חבר</ins></div>")
    end

    it "should handle multi-word changes in Vietnamese" do
      diff = described_class.diff('Tôi đang học Ruby', 'Tôi đang học Python rất vui')
      expect(diff).to eq("Tôi đang học <del class=\"diffmod\">Ruby</del><ins class=\"diffmod\">Python rất vui</ins>")
    end

    it "should support Chinese" do
      diff = described_class.diff('这个是中文内容, Ruby is the bast', '这是中国语内容，Ruby is the best language.')
      expect(diff).to eq("这<del class=\"diffdel\">个</del>是中<del class=\"diffmod\">文</del><ins class=\"diffmod\">国语</ins>内容<del class=\"diffmod\">, </del><ins class=\"diffmod\">，</ins>Ruby is the <del class=\"diffmod\">bast</del><ins class=\"diffmod\">best language.</ins>")
    end

    it "should support Hindi (Devanagari)" do
      diff = described_class.diff('नमस्ते दुनिया', 'नमस्ते प्यारी दुनिया')
      expect(diff).to eq("नमस्ते <ins class=\"diffins\">प्यारी </ins>दुनिया")
    end

    it "should support Thai" do
      diff = described_class.diff('สวัสดีชาวโลก', 'สวัสดีชาวโลกที่สวยงาม')
      expect(diff).to eq("สวัสดีชาวโลก<ins class=\"diffins\">ที่สวยงาม</ins>")
    end

    it "should support Japanese" do
      diff = described_class.diff('こんにちは世界', 'こんにちは美しい世界')
      expect(diff).to eq("こんにちは<ins class=\"diffins\">美しい</ins>世界")
    end

    it "should support Korean" do
      diff = described_class.diff('안녕하세요 세계', '안녕하세요 아름다운 세계')
      expect(diff).to eq("안녕하세요 <ins class=\"diffins\">아름다운 </ins>세계")
    end

    it "should support Armenian" do
      diff = described_class.diff('Բարեւ աշխարհ', 'Բարեւ գեղեցիկ աշխարհ')
      expect(diff).to eq("Բարեւ <ins class=\"diffins\">գեղեցիկ </ins>աշխարհ")
    end

    it "should support Georgian" do
      diff = described_class.diff('გამარჯობა მსოფლიო', 'გამარჯობა ლამაზი მსოფლიო')
      expect(diff).to eq("გამარჯობა <ins class=\"diffins\">ლამაზი </ins>მსოფლიო")
    end

    it "should support Amharic (Ethiopic)" do
      diff = described_class.diff('ሰላም ዓለም', 'ሰላም ውብ ዓለም')
      expect(diff).to eq("ሰላም <ins class=\"diffins\">ውብ </ins>ዓለም")
    end

    it "should support Khmer" do
      diff = described_class.diff('សួស្តី​ពិភពលោក', 'សួស្តី​ពិភពលោក ស្អាត')
      expect(diff).to eq("សួស្តី​ពិភពលោក<ins class=\"diffins\"> ស្អាត</ins>")
    end

    it "should support Lao" do
      diff = described_class.diff('ສະບາຍດີ ໂລກ', 'ສະບາຍດີ ໂລກ ສວຍງາມ')
      expect(diff).to eq("ສະບາຍດີ ໂລກ<ins class=\"diffins\"> ສວຍງາມ</ins>")
    end

    it "should support Myanmar (Burmese)" do
      diff = described_class.diff('မင်္ဂလာပါ ကမ္ဘာ', 'မင်္ဂလာပါ လှပသော ကမ္ဘာ')
      expect(diff).to eq("မင်္ဂလာပါ <ins class=\"diffins\">လှပသော </ins>ကမ္ဘာ")
    end

    it "should support Sinhala" do
      diff = described_class.diff('ආයුබෝවන් ලෝකය', 'ආයුබෝවන් ලස්සන ලෝකය')
      expect(diff).to eq("ආයුබෝවන් <ins class=\"diffins\">ලස්සන </ins>ලෝකය")
    end

    it "should support Tamil" do
      diff = described_class.diff('வணக்கம் உலகம்', 'வணக்கம் அழகிய உலகம்')
      expect(diff).to eq("வணக்கம் <ins class=\"diffins\">அழகிய </ins>உலகம்")
    end

    it "should support Telugu" do
      diff = described_class.diff('నమస్కారం ప్రపంచం', 'నమస్కారం అందమైన ప్రపంచం')
      expect(diff).to eq("నమస్కారం <ins class=\"diffins\">అందమైన </ins>ప్రపంచం")
    end

    it "should support Kannada" do
      diff = described_class.diff('ನಮಸ್ಕಾರ ಜಗತ್ತು', 'ನಮಸ್ಕಾರ ಸುಂದರ ಜಗತ್ತು')
      expect(diff).to eq("ನಮಸ್ಕಾರ <ins class=\"diffins\">ಸುಂದರ </ins>ಜಗತ್ತು")
    end

    it "should support Malayalam" do
      diff = described_class.diff('നമസ്കാരം ലോകം', 'നമസ്കാരം സുന്ദരമായ ലോകം')
      expect(diff).to eq("നമസ്കാരം <ins class=\"diffins\">സുന്ദരമായ </ins>ലോകം")
    end

    it "should support Tibetan" do
      diff = described_class.diff('བཀྲ་ཤིས་བདེ་ལེགས། འཛམ་གླིང་', 'བཀྲ་ཤིས་བདེ་ལེགས། མཛེས་སྡུག་ལྡན་པའི་ འཛམ་གླིང་')
      expect(diff).to eq("བཀྲ་ཤིས་བདེ་ལེགས། <ins class=\"diffins\">མཛེས་སྡུག་ལྡན་པའི་ </ins>འཛམ་གླིང་")
    end

    it "should support Mongolian" do
      diff = described_class.diff('Сайн байна уу дэлхий', 'Сайн байна уу гоё дэлхий')
      expect(diff).to eq("Сайн байна уу <ins class=\"diffins\">гоё </ins>дэлхий")
    end

    pending "should support mixed scripts and languages" do
      diff = described_class.diff('Hello नमस्ते こんにちは', 'Hello नमस्ते मित्र こんにちは 世界')
      expect(diff).to eq("Hello नमस्ते <ins class=\"diffins\">मित्र </ins>こんにちは<ins class=\"diffins\"> 世界</ins>")
    end

    pending "should handle mixed languages with HTML tags" do
      diff = described_class.diff('<div>안녕하세요 世界</div>', '<div>안녕하세요 아름다운 世界</div>')
      expect(diff).to eq("<div>안녕하세요 <ins class=\"diffins\">아름다운 </ins>世界</div>")
    end

    it "should handle complex changes in Japanese" do
      diff = described_class.diff('日本語は面白いです', '日本語は素晴らしいです')
      expect(diff).to eq("日本語は<del class=\"diffmod\">面白</del><ins class=\"diffmod\">素晴らし</ins>いです")
    end

    it "should detect changes within Devanagari words" do
      diff = described_class.diff('मैं प्रोग्रामिंग पसंद करता हूँ', 'मैं कोडिंग पसंद करता हूँ')
      expect(diff).to eq("मैं <del class=\"diffmod\">प्रोग्रामिंग</del><ins class=\"diffmod\">कोडिंग</ins> पसंद करता हूँ")
    end
  end

  describe "HTML entities" do
    it "should support basic HTML entities" do
      diff = described_class.diff('a &lt; b &gt; c', 'a &lt; b &amp; c')
      expect(diff).to eq("a &lt; b <del class=\"diffmod\">&gt;</del><ins class=\"diffmod\">&amp;</ins> c")
    end

    it "should handle entity changes" do
      diff = described_class.diff('&amp; &lt; &gt; &quot; &apos;', '&amp; &lt; &gt; &apos; &quot;')
      expect(diff).to eq("&amp; &lt; &gt; <ins class=\"diffins\">&apos; </ins>&quot;<del class=\"diffdel\"> &apos;</del>")
    end

    it "should preserve numeric HTML entities" do
      diff = described_class.diff('&#8364; is euro', '&#8364; is the euro symbol')
      expect(diff).to eq("&#8364; is <ins class=\"diffins\">the </ins>euro<ins class=\"diffins\"> symbol</ins>")
    end

    it "should diff content with multiple entities correctly" do
      diff = described_class.diff('&lt;p&gt;text&lt;/p&gt;', '&lt;p&gt;new text&lt;/p&gt;')
      expect(diff).to eq("&lt;p&gt;<ins class=\"diffins\">new </ins>text&lt;/p&gt;")
    end

    it "should treat entities as single units" do
      diff = described_class.diff('a&nbsp;b', 'a b')
      expect(diff).to eq("a<del class=\"diffmod\">&nbsp;</del><ins class=\"diffmod\"> </ins>b")
    end

    it "should handle mixed entities and normal text" do
      diff = described_class.diff('&copy; 2023 Company', '&copy; 2024 New Company')
      expect(diff).to eq("&copy; <del class=\"diffmod\">2023</del><ins class=\"diffmod\">2024 New</ins> Company")
    end

    it "should diff escaped HTML tags correctly" do
      diff = described_class.diff('&lt;div class="old"&gt;content&lt;/div&gt;',
                                  '&lt;div class="new"&gt;content&lt;/div&gt;')
      expect(diff).to eq("&lt;div class=\"<del class=\"diffmod\">old</del><ins class=\"diffmod\">new</ins>\"&gt;content&lt;/div&gt;")
    end

    it "should handle HTML entities in different scripts" do
      diff = described_class.diff('&lt;span&gt;привет&lt;/span&gt;', '&lt;span&gt;здравствуйте&lt;/span&gt;')
      expect(diff).to eq("&lt;span&gt;<del class=\"diffmod\">привет</del><ins class=\"diffmod\">здравствуйте</ins>&lt;/span&gt;")
    end

    it "should correctly process HTML entities in attributes" do
      diff = described_class.diff('&lt;a title="&amp; more"&gt;link&lt;/a&gt;',
                                  '&lt;a title="&amp; less"&gt;link&lt;/a&gt;')
      expect(diff).to eq("&lt;a title=\"&amp; <del class=\"diffmod\">more</del><ins class=\"diffmod\">less</ins>\"&gt;link&lt;/a&gt;")
    end

    it "should handle complex entity sequences" do
      diff = described_class.diff('&alpha;&beta;&gamma;', '&alpha;&delta;&gamma;')
      expect(diff).to eq("&alpha;<del class=\"diffmod\">&beta;</del><ins class=\"diffmod\">&delta;</ins>&gamma;")
    end
  end
end
