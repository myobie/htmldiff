require 'bundler/gem_tasks'
require 'rubygems/package_task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

gemspec = Gem::Specification.load(File.expand_path('htmldiff.gemspec', __dir__))
Gem::PackageTask.new(gemspec) do |pkg|
  pkg.gem_spec = gemspec
end

desc 'Install the gem locally'
task install: [:package] do
  sh "gem install pkg/#{GEM}-#{GEM_VERSION}.gem"
end
