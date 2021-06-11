# frozen_string_literal: true

module GithubBot
  VERSION = '0.1.0'

  # version module
  module Version
    MAJOR, MINOR, PATCH, *BUILD = VERSION.split '.'
    NUMBERS = [MAJOR, MINOR, PATCH, *BUILD].freeze
  end
end
