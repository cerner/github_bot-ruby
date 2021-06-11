# frozen_string_literal: true

require 'rails'

module GithubBot
  class Engine < ::Rails::Engine
    isolate_namespace GithubBot
  end
end
