# frozen_string_literal: true

# Only include in the context of a rails application
return unless defined?(Rails)

require 'octokit'

module GithubBot
  # Public: Railtie for injecting configuration of Octokit in a Rails environment
  class Railtie < ::Rails::Railtie
    config.after_initialize do
      Octokit.configure { |c| c.api_endpoint = "https://#{ENV['GITHUB_HOST']}/api/v3/" } if ENV['GITHUB_HOST'].present?
    end
  end
end
