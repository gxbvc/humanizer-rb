# frozen_string_literal: true

require_relative "lib/humanizer/version"

Gem::Specification.new do |spec|
  spec.name          = "humanizer-rb"
  spec.version       = Humanizer::VERSION
  spec.authors       = ["Christian Genco"]
  spec.email         = ["christian@gen.co"]

  spec.summary       = "Detect AI-generated writing patterns"
  spec.description   = "Scores text 0-100 for AI writing patterns using 32 pattern detectors, 500+ vocabulary terms, and statistical text analysis. Ruby port of the humanizer Node.js tool."
  spec.homepage      = "https://github.com/gxbvc/humanizer-rb"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files         = Dir["lib/**/*.rb", "bin/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.bindir        = "bin"
  spec.executables   = ["humanizer"]
  spec.require_paths = ["lib"]

  # Zero runtime dependencies — all pure Ruby
end
