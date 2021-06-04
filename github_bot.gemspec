# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'github_bot/version'

Gem::Specification.new do |spec|
  spec.name          = 'github_bot'
  spec.version       = GithubBot::VERSION
  spec.authors       = ['Greg Howdeshell']
  spec.email         = ['greg.howdeshell@gmail.com']

  spec.summary       = 'A rubygem designed to assist in the creation of GitHub bot applications.'
  spec.description = <<~DESC
  A rubygem designed to assist in the creation of GitHub bot applications.
  DESC
  spec.homepage      = 'https://github.com/poloka/github_bot-ruby'
  spec.license       = 'Apache-2.0'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         =
    Dir.chdir(File.expand_path(__dir__)) do
      `git ls-files -z`.split("\x0").reject { |f| f.match(/^(test|spec|features)\//) }
    end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6.2'

  
end
