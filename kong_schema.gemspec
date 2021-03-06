# coding: utf-8

require_relative "./lib/kong_schema/version"

Gem::Specification.new do |spec|
  spec.name          = "kong_schema"
  spec.version       = KongSchema::VERSION
  spec.authors       = ["Ahmad Amireh"]
  spec.email         = ["ahmad@instructure.com"]
  spec.summary       = "Configure Kong from a file using its REST API."
  spec.license       = 'AGPL-3.0'
  spec.homepage      = 'https://github.com/amireh/kong_schema'

  spec.files         =  Dir.glob("lib/**/*") +
                        Dir.glob("ext/**/*") +
                        Dir.glob("bin/*") +
                        %w[ README.md CHANGELOG.md LICENSE.md Gemfile Gemfile.lock ]
  spec.executables   = %w(kong_schema)
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = %w(lib)

  spec.add_dependency "gli", "~> 2.16"
  spec.add_dependency "diffy", "~> 3.2"
  spec.add_dependency "json", "~> 2.1"
  spec.add_dependency "kong", "~> 0.3"
  spec.add_dependency "tty-prompt", "~> 0.16"
  spec.add_dependency "tty-table", "~> 0.10"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rspec", "~> 3.6"
  spec.add_development_dependency "simplecov", "~> 0.15"
  spec.add_development_dependency "simplecov_compact_json", "~> 1.0"
end
