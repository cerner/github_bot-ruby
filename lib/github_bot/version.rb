# frozen_string_literal: true

module GithubBot
  VERSION = '0.3.1'

  # version module
  module Version
    MAJOR, MINOR, PATCH, *BUILD = VERSION.split '.'
    NUMBERS = [MAJOR, MINOR, PATCH, *BUILD].freeze
  end
end
