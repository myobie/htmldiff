# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{htmldiff}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nathan Herald"]
  s.autorequire = %q{htmldiff}
  s.date = %q{2008-11-21}
  s.description = %q{HTML diffs of text (borrowed from a wiki software I no longer remember)}
  s.email = %q{nathan@myobie.com}
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/htmldiff.rb", "spec/htmldiff_spec.rb", "spec/spec_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/myobie/htmldiff}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{HTML diffs of text (borrowed from a wiki software I no longer remember)}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
