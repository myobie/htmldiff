# frozen_string_literal: true

require_relative 'lib/html_diff/version'

Gem::Specification.new do |spec|
  spec.name = 'htmldiff'
  spec.version = HTMLDiff::VERSION
  spec.authors = ['Nathan Herald', 'Johnny Shields']
  spec.email = 'nathan@myobie.com'
  spec.summary = 'HTML diffs of text'
  spec.description = 'Generates diffs of text in HTML format based on the LCS algorithm.'
  spec.homepage = 'http://github.com/myobie/htmldiff'
  spec.license = 'MIT'

  spec.add_dependency 'diff-lcs'

  spec.files = Dir.glob('lib/**/*') + %w[LICENSE README]
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
end
