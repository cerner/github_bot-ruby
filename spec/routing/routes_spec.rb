# frozen_string_literal: true

require 'spec_helper'

module GithubBot
  module Webhooks
    describe GithubController do
      it 'routes to github_bot/webhooks/github#validate' do
        expect(post: 'webhooks').to route_to(
          controller: 'github_bot/webhooks/github',
          action: 'validate',
          format: :json
        )
      end
    end
  end
end
