# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tdiary/style/gfm/version'

Gem::Specification.new do |spec|
  spec.name          = "tdiary-style-gfm"
  spec.version       = TDiary::Style::Gfm::VERSION
  spec.authors       = ["SHIBATA Hiroshi"]
  spec.email         = ["shibata.hiroshi@gmail.com"]
  spec.description   = %q{GFM Style for tDiary}
  spec.summary       = %q{GFM Style for tDiary}
  spec.homepage      = "https://github.com/tdiary/tdiary-style-gfm"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'github-markdown'
  spec.add_dependency 'pygments.rb'
  spec.add_dependency 'twitter-text'
  spec.add_dependency 'gemoji'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
