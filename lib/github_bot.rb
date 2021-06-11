# frozen_string_literal: true

Dir.glob(File.join(File.dirname(__FILE__), 'github_bot', '**/*.rb'), &method(:require))

# Public: The github bot is utilized for assistance with webhook interactions provided by
# the incoming github events
module GithubBot
  mattr_accessor :draw_routes_in_host_app
  self.draw_routes_in_host_app = true
end
