# coding: utf-8
require File.dirname(__FILE__) + '/spec_helper'
require 'htmldiff'

class TestDiff
  extend HTMLDiff
end

describe "htmldiff" do

  it "should diff text" do
    diff = TestDiff.diff('a word is here', 'a nother word is there')
    diff.should == "a<ins class=\"diffins\"> nother</ins> word is <del class=\"diffmod\">here</del><ins class=\"diffmod\">there</ins>"
  end

  it "should insert a letter and a space" do
    diff = TestDiff.diff('a c', 'a b c')
    diff.should == "a <ins class=\"diffins\">b </ins>c"
  end

  it "should remove a letter and a space" do
    diff = TestDiff.diff('a b c', 'a c')
    diff.should == "a <del class=\"diffdel\">b </del>c"
  end

  it "should change a letter" do
    diff = TestDiff.diff('a b c', 'a d c')
    diff.should == "a <del class=\"diffmod\">b</del><ins class=\"diffmod\">d</ins> c"
  end

  it "should support accents" do
    diff = TestDiff.diff('blåbær dèjá vu', 'blåbær deja vu')
    diff.should == "blåbær <del class=\"diffmod\">dèjá</del><ins class=\"diffmod\">deja</ins> vu"
  end

  it "should support Chinese" do
    diff = TestDiff.diff('这个是中文内容, Ruby is the bast', '这是中国语内容，Ruby is the best language.')
    diff.should == "这<del class=\"diffdel\">个</del>是中<del class=\"diffmod\">文</del><ins class=\"diffmod\">国语</ins>内容<del class=\"diffmod\">, </del><ins class=\"diffmod\">，</ins>Ruby is the <del class=\"diffmod\">bast</del><ins class=\"diffmod\">best language.</ins>"
  end

  it "should support Cyrillic" do
    diff = TestDiff.diff('Привет, как дела?', 'Привет, хорошо дела!')
    diff.should == "Привет, <del class=\"diffmod\">как</del><ins class=\"diffmod\">хорошо</ins> дела<del class=\"diffmod\">?</del><ins class=\"diffmod\">!</ins>"
  end

  it "should support Greek" do
    diff = TestDiff.diff('Καλημέρα κόσμε', 'Καλησπέρα κόσμε')
    diff.should == "<del class=\"diffmod\">Καλημέρα</del><ins class=\"diffmod\">Καλησπέρα</ins> κόσμε"
  end

  it "should support Arabic" do
    diff = TestDiff.diff('مرحبا بالعالم', 'مرحبا جميل بالعالم')
    diff.should == "مرحبا <ins class=\"diffins\">جميل </ins>بالعالم"
  end

  it "should support Hebrew" do
    diff = TestDiff.diff('שלום עולם', 'שלום עולם קטן')
    diff.should == "שלום עולם<ins class=\"diffins\"> קטן</ins>"
  end

  it "should support Vietnamese" do
    diff = TestDiff.diff('Xin chào thế giới', 'Xin chào thế giới mới')
    diff.should == "Xin chào thế giới<ins class=\"diffins\"> mới</ins>"
  end

  it "should handle mixed scripts" do
    diff = TestDiff.diff('Hello مرحبا Привет', 'Hello مرحبا جدا Привет')
    diff.should == "Hello مرحبا <ins class=\"diffins\">جدا </ins>Привет"
  end

  it "should support Cyrillic with HTML tags" do
    diff = TestDiff.diff('<div>Текст в теге</div>', '<div>Новый текст в теге</div>')
    diff.should == "<div><del class=\"diffmod\">Текст</del><ins class=\"diffmod\">Новый текст</ins> в теге</div>"
  end

  it "should support Arabic with HTML tags" do
    diff = TestDiff.diff('<span>النص في العلامة</span>', '<span>النص الجديد في العلامة</span>')
    diff.should == "<span>النص<ins class=\"diffins\"> الجديد</ins> في العلامة</span>"
  end

  it "should handle complex Hebrew changes" do
    diff = TestDiff.diff('אני אוהב לתכנת בשפת רובי', 'אני אוהב מאוד לתכנת בשפת פייתון')
    diff.should == "אני אוהב<ins class=\"diffins\"> מאוד</ins> לתכנת בשפת <del class=\"diffmod\">רובי</del><ins class=\"diffmod\">פייתון</ins>"
  end

  it "should support Vietnamese diacritics" do
    diff = TestDiff.diff('Tôi yêu lập trình', 'Tôi thích lập trình')
    diff.should == "Tôi <del class=\"diffmod\">yêu</del><ins class=\"diffmod\">thích</ins> lập trình"
  end

  it "should handle mixed languages with punctuation" do
    diff = TestDiff.diff('Hello, Привет! مرحبا. שלום', 'Hello, Привет! مرحبا جدا. שלום עולם')
    diff.should == "Hello, Привет! <del class=\"diffmod\">مرحبا.</del><ins class=\"diffmod\">مرحبا جدا.</ins> שלום<ins class=\"diffins\"> עולם</ins>"
  end

  it "should support Greek with formatting tags" do
    diff = TestDiff.diff('<b>Γεια σας</b> κόσμε', '<b>Γεια σου</b> κόσμε')
    diff.should == "<b>Γεια <del class=\"diffmod\">σας</del><ins class=\"diffmod\">σου</ins></b> κόσμε"
  end

  it "should detect changes within Arabic words" do
    diff = TestDiff.diff('البرمجة ممتعة', 'البرمجة سهلة')
    diff.should == "البرمجة <del class=\"diffmod\">ممتعة</del><ins class=\"diffmod\">سهلة</ins>"
  end

  it "should properly handle RTL text with HTML" do
    diff = TestDiff.diff('<div dir="rtl">שלום עולם</div>', '<div dir="rtl">שלום חבר</div>')
    diff.should == "<div dir=\"rtl\">שלום <del class=\"diffmod\">עולם</del><ins class=\"diffmod\">חבר</ins></div>"
  end

  it "should handle multi-word changes in Vietnamese" do
    diff = TestDiff.diff('Tôi đang học Ruby', 'Tôi đang học Python rất vui')
    diff.should == "Tôi đang học <del class=\"diffmod\">Ruby</del><ins class=\"diffmod\">Python rất vui</ins>"
  end

  it "should support email addresses" do
    diff = TestDiff.diff('I sent an email to foo@bar.com!',
                         'I sent an email to baz@bar.com!',)
    diff.should == "I sent an email to <del class=\"diffmod\">foo@bar.com</del><ins class=\"diffmod\">baz@bar.com</ins>!"
  end

  it "should support sentences" do
    diff = TestDiff.diff('The quick red fox? "jumped" over; the "lazy", brown dog! Didn\'t he?',
                         'The quick blue fox? \'hopped\' over! the "active", purple dog! Did he not?')
    diff.should == "The quick <del class=\"diffmod\">red</del><ins class=\"diffmod\">blue</ins> fox? <del class=\"diffmod\">\"jumped\"</del><ins class=\"diffmod\">'hopped'</ins> over<del class=\"diffmod\">;</del><ins class=\"diffmod\">!</ins> the \"<del class=\"diffmod\">lazy</del><ins class=\"diffmod\">active</ins>\", <del class=\"diffmod\">brown</del><ins class=\"diffmod\">purple</ins> dog! <del class=\"diffmod\">Didn't</del><ins class=\"diffmod\">Did</ins> he<ins class=\"diffins\"> not</ins>?"
  end

  it "should support escaped HTML" do
    diff = TestDiff.diff('&lt;div&gt;this &lt;span tag=1 class="foo"&gt;is a sentence&lt;/span&gt; test&lt;/div&gt;',
                         '&lt;div&gt;this &lt;span class="bar" tag=2&gt;is a string&lt;/label&gt; also a test&lt;/label&gt;')
    diff.should == "&lt;div&gt;this &lt;span <del class=\"diffdel\">tag=1 </del>class=\"<del class=\"diffmod\">foo</del><ins class=\"diffmod\">bar</ins>\"<ins class=\"diffins\"> tag=2</ins>&gt;is a <del class=\"diffmod\">sentence</del><ins class=\"diffmod\">string</ins>&lt;/<del class=\"diffmod\">span</del><ins class=\"diffmod\">label</ins>&gt;<ins class=\"diffins\"> also a</ins> test&lt;/<del class=\"diffmod\">div</del><ins class=\"diffmod\">label</ins>&gt;"
  end

  it "should support img tags insertion" do
    oldv = 'a b c'
    newv = 'a b <img src="some_url" /> c'
    diff = TestDiff.diff(oldv, newv)
    diff.should == "a b <ins class=\"diffins\"><img src=\"some_url\" /> </ins>c"
  end

  it "should support img tags deletion" do
    oldv = 'a b c'
    newv = 'a b <img src="some_url" /> c'
    diff = TestDiff.diff(newv, oldv)
    diff.should == "a b <del class=\"diffdel\"><img src=\"some_url\" /> </del>c"
  end

  describe "HTML entities" do
    it "should support basic HTML entities" do
      diff = TestDiff.diff('a &lt; b &gt; c', 'a &lt; b &amp; c')
      diff.should == "a &lt; b <del class=\"diffmod\">&gt;</del><ins class=\"diffmod\">&amp;</ins> c"
    end

    it "should handle entity changes" do
      diff = TestDiff.diff('&amp; &lt; &gt; &quot; &apos;', '&amp; &lt; &gt; &apos; &quot;')
      diff.should == "&amp; &lt; &gt; <ins class=\"diffins\">&apos; </ins>&quot;<del class=\"diffdel\"> &apos;</del>"
    end

    it "should preserve numeric HTML entities" do
      diff = TestDiff.diff('&#8364; is euro', '&#8364; is the euro symbol')
      diff.should == "&#8364; is <ins class=\"diffins\">the </ins>euro<ins class=\"diffins\"> symbol</ins>"
    end

    it "should diff content with multiple entities correctly" do
      diff = TestDiff.diff('&lt;p&gt;text&lt;/p&gt;', '&lt;p&gt;new text&lt;/p&gt;')
      diff.should == "&lt;p&gt;<ins class=\"diffins\">new </ins>text&lt;/p&gt;"
    end

    pending "should treat entities as single units" do
      diff = TestDiff.diff('a&nbsp;b', 'a b')
      diff.should == "a<del class=\"diffmod\">&nbsp;</del><ins class=\"diffmod\"> </ins>b"
    end

    it "should handle mixed entities and normal text" do
      diff = TestDiff.diff('&copy; 2023 Company', '&copy; 2024 New Company')
      diff.should == "&copy; <del class=\"diffmod\">2023</del><ins class=\"diffmod\">2024 New</ins> Company"
    end

    it "should diff escaped HTML tags correctly" do
      diff = TestDiff.diff('&lt;div class="old"&gt;content&lt;/div&gt;',
                           '&lt;div class="new"&gt;content&lt;/div&gt;')
      diff.should == "&lt;div class=\"<del class=\"diffmod\">old</del><ins class=\"diffmod\">new</ins>\"&gt;content&lt;/div&gt;"
    end

    it "should handle HTML entities in different scripts" do
      diff = TestDiff.diff('&lt;span&gt;привет&lt;/span&gt;', '&lt;span&gt;здравствуйте&lt;/span&gt;')
      diff.should == "&lt;span&gt;<del class=\"diffmod\">привет</del><ins class=\"diffmod\">здравствуйте</ins>&lt;/span&gt;"
    end

    it "should correctly process HTML entities in attributes" do
      diff = TestDiff.diff('&lt;a title="&amp; more"&gt;link&lt;/a&gt;',
                           '&lt;a title="&amp; less"&gt;link&lt;/a&gt;')
      diff.should == "&lt;a title=\"&amp; <del class=\"diffmod\">more</del><ins class=\"diffmod\">less</ins>\"&gt;link&lt;/a&gt;"
    end

    it "should handle complex entity sequences" do
      diff = TestDiff.diff('&alpha;&beta;&gamma;', '&alpha;&delta;&gamma;')
      diff.should == "&alpha;<del class=\"diffmod\">&beta;</del><ins class=\"diffmod\">&delta;</ins>&gamma;"
    end
  end
end
