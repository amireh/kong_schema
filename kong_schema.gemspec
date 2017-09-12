# coding: utf-8

require_relative "./lib/kong_schema/version"

Gem::Specification.new do |spec|
  spec.name          = "kong_schema"
  spec.version       = KongSchema::VERSION
  spec.authors       = ["Ahmad Amireh"]
  spec.email         = ["ahmad@instructure.com"]
  spec.summary       = "Configure Kong from a file using its REST API."
  spec.license       = 'AGPL-3.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = %w(lib)

  spec.add_dependency "kong", "~> 0.3.0"
  spec.add_dependency "tty-table", "~> 0.8.0"
  spec.add_dependency "tty-prompt", "~> 0.13.2"
  spec.add_dependency "diffy", "~> 3.1.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov_compact_json"
end
