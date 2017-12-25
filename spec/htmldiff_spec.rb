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

  it "should support Chinese" do
    diff = TestDiff.diff('这个是中文内容, Ruby is the bast', '这是中国语内容，Ruby is the best language.')
    diff.should == "<del class=\"diffmod\">这个是中文内容, </del><ins class=\"diffmod\">这是中国语内容，</ins>Ruby is the <del class=\"diffmod\">bast</del><ins class=\"diffmod\">best language.</ins>"
  end

  it "should support accents" do
    diff = TestDiff.diff('blåbær dèjá vu', 'blåbær deja vu')
    diff.should == "blåbær <del class=\"diffmod\">dèjá</del><ins class=\"diffmod\">deja</ins> vu"
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
  
end
