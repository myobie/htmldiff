# coding: utf-8
require File.dirname(__FILE__) + '/spec_helper'
require 'htmldiff'

class TestDiff
  extend HTMLDiff
end

describe "htmldiff" do
  
  it "should diff text" do
    diff = TestDiff.diff('a word is here', 'a nother word is there')
    expect(diff).to  eq("a<ins class=\"diffins\"> nother</ins> word is <del class=\"diffmod\">here</del><ins class=\"diffmod\">there</ins>")
  end
  
  it "should insert a letter and a space" do
    diff = TestDiff.diff('a c', 'a b c')
    expect(diff).to eq("a <ins class=\"diffins\">b </ins>c")
  end
  
  it "should remove a letter and a space" do
    diff = TestDiff.diff('a b c', 'a c')
    expect(diff).to eq("a <del class=\"diffdel\">b </del>c")
  end
  
  it "should change a letter" do
    diff = TestDiff.diff('a b c', 'a d c')
    expect(diff).to eq("a <del class=\"diffmod\">b</del><ins class=\"diffmod\">d</ins> c")
  end

  it "should support Chinese" do
    pending
    diff = TestDiff.diff('这个是中文内容, Ruby is the bast', '这是中国语内容，Ruby is the best language.')
    expect(diff).to eq("这<del class=\"diffdel\">个</del>是中<del class=\"diffmod\">文</del><ins class=\"diffmod\">国语</ins>内<del class=\"diffmod\">容, Ruby</del><ins class=\"diffmod\">容，Ruby</ins> is the <del class=\"diffmod\">bast</del><ins class=\"diffmod\">best language.</ins>")
  end
  
end
