# frozen_string_literal: true

module GithubBot
  class Engine < ::Rails::Engine
    isolate_namespace GithubBot
  end
end
