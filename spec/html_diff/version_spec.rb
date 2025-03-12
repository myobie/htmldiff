# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'HTMLDiff::VERSION' do
  it 'has a version number' do
    expect(HTMLDiff::VERSION).to match(/\A\d+\.\d+\.\d+(?:-.+)?\z/)
  end
end
