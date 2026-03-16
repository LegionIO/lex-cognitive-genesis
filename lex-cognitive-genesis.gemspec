# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_genesis/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-genesis'
  spec.version       = Legion::Extensions::CognitiveGenesis::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Cognitive Genesis'
  spec.description   = 'De novo concept creation for brain-modeled agentic AI — the 200th LegionIO cognitive extension. ' \
                       'Seeds proto-concepts, germinates them into novel cognitive categories, and tracks their adoption.'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-genesis'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/lex-cognitive-genesis'
  spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/lex-cognitive-genesis'
  spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/lex-cognitive-genesis'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/lex-cognitive-genesis/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
