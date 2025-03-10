require 'rubygems/package_task'
require 'rspec/core/rake_task'

spec = Gem::Specification.load(File.expand_path('htmldiff.gemspec', __dir__))

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

task :default => :spec

Gem::PackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install the gem locally"
task :install => [:package] do
  sh "gem install pkg/#{GEM}-#{GEM_VERSION}.gem"
end
