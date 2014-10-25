# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'postgresql-types/version'

Gem::Specification.new do |spec|
  spec.name          = "postgresql-types"
  spec.version       = PostgresqlTypes::VERSION
  spec.authors       = ["Kip Cole"]
  spec.email         = ["kipcole9@gmail.com"]
  spec.summary       = %q{Activerecord support for additional postgres data types}
  spec.description   = <<-TEXT
                        Active Record support for additional postgresql data types: geometry, geography (from PostGis),
                        an a currency data type (composite type), meter unit type.
                       TEXT
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'rgeo'
  spec.add_dependency 'unitable'
  spec.add_dependency 'activerecord', '>4.1'
  spec.add_dependency 'activesupport', '>4.1'
  spec.add_dependency 'twitter_cldr'
  
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
