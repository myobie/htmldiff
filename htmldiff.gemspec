# frozen_string_literal: true

require_relative 'lib/html_diff/version'

Gem::Specification.new do |spec|
  spec.name = 'htmldiff'
  spec.version = '1.0.0'
  spec.authors = ['Nathan Herald']
  spec.email = 'nathan@myobie.com'
  spec.summary = 'HTML diffs of text'
  spec.description = 'Generates diffs of text in HTML format based on the LCS algorithm.'
  spec.homepage = 'http://github.com/myobie/htmldiff'
  spec.license = 'MIT'

  spec.add_dependency 'diff-lcs'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'

  spec.files         = Dir.glob('lib/**/*') + %w[LICENSE README]
  spec.test_files    = Dir.glob('spec/**/*')
  spec.require_paths = ['lib']
end
