# frozen_string_literal: true

Dir.glob(File.join(File.dirname(__FILE__), 'github_bot', '**/*.rb'), &method(:require))

# Public: The github bot is utilized for assistance with webhook interactions provided by
# the incoming github events
module GithubBot
end
