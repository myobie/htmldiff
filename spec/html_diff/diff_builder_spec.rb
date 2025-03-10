# frozen_string_literal: true

require_relative '../spec_helper'

# rubocop:disable Style/ClassVars
RSpec.describe HTMLDiff::DiffBuilder do
  let(:old_string) { 'This is an old string' }
  let(:new_string) { 'This is a new string' }

  describe '#initialize' do
    it 'stores the old and new strings' do
      builder = described_class.new(old_string, new_string)
      expect(builder.instance_variable_get(:@old_string)).to eq(old_string)
      expect(builder.instance_variable_get(:@new_string)).to eq(new_string)
    end

    it 'outputs a deprecation warning' do
      described_class.class_variable_set(:@@warned_init, false)
      expect { described_class.new(old_string, new_string) }.to output(/HTMLDiff::DiffBuilder is deprecated/).to_stderr
    end

    it 'only outputs the warning once' do
      described_class.class_variable_set(:@@warned_init, false)
      described_class.new(old_string, new_string)
      expect { described_class.new(old_string, new_string) }.not_to output.to_stderr
    end
  end

  describe '#build' do
    let(:builder) { described_class.new(old_string, new_string) }

    it 'calls HTMLDiff.diff with the stored strings' do
      result = builder.build
      expect(result).to eq 'This is <del class="diffmod">an</del><ins class="diffmod">a</ins> <del class="diffmod">old</del><ins class="diffmod">new</ins> string'
    end

    it 'outputs a deprecation warning' do
      described_class.class_variable_set(:@@warned_build, false)
      expect { builder.build }.to output(/\AHTMLDiff::DiffBuilder#build is deprecated/).to_stderr
    end

    it 'only outputs the warning once' do
      described_class.class_variable_set(:@@warned_build, false)
      builder.build
      expect { builder.build }.not_to output.to_stderr
    end
  end
end
# rubocop:enable Style/ClassVars
