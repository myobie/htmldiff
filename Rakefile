require 'rubygems'
require 'rubygems/package_task'
require 'rubygems/specification'
require 'date'
require 'rspec/core/rake_task'

GEM = "htmldiff"
GEM_VERSION = "0.0.1"
AUTHOR = "Nathan Herald"
EMAIL = "nathan@myobie.com"
HOMEPAGE = "http://github.com/myobie/htmldiff"
SUMMARY = "HTML diffs of text (borrowed from a wiki software I no longer remember)"

spec = Gem::Specification.new do |s|
  s.name = GEM
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE", 'TODO']
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  
  # Uncomment this to add a dependency
  # s.add_dependency "foo"
  
  s.require_path = 'lib'
  s.autorequire = GEM
  s.files = %w(LICENSE README Rakefile TODO) + Dir.glob("{lib,spec}/**/*")
end

task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = FileList['spec/**/*_spec.rb']
  #t.rspec_opts = %w(-fs --color)
  t.rspec_opts = %w(-fp --color)
end


Gem::PackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "install the gem locally"
task :install => [:package] do
  sh %{sudo gem install pkg/#{GEM}-#{GEM_VERSION}}
end

desc "create a gemspec file"
task :make_spec do
  File.open("#{GEM}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end
