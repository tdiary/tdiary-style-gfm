# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tdiary/style/gfm/version'

Gem::Specification.new do |spec|
  spec.name          = "tdiary-style-gfm"
  spec.version       = TDiary::Style::Gfm::VERSION
  spec.authors       = ["SHIBATA Hiroshi"]
  spec.email         = ["hsbt@ruby-lang.org"]
  spec.description   = %q{GFM Style for tDiary}
  spec.summary       = %q{GFM Style for tDiary}
  spec.homepage      = "https://github.com/tdiary/tdiary-style-gfm"
  spec.license       = "GPL-3.0"
  spec.required_ruby_version = ">= 2.2.2"

  spec.files         = Dir["README.md", "LICENSE.txt", "tdiary-style-gfm.gemspec", "lib/**/*"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'commonmarker'
  spec.add_dependency 'twitter-text', '>= 2.0'
  spec.add_dependency 'emot'
end
