# frozen_string_literal: true

module GithubBot
  VERSION = '0.2.2'

  # version module
  module Version
    MAJOR, MINOR, PATCH, *BUILD = VERSION.split '.'
    NUMBERS = [MAJOR, MINOR, PATCH, *BUILD].freeze
  end
end
