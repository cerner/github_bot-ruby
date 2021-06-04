# frozen_string_literal: true

require_relative '../application_controller'

module GithubBot
  module Webhooks
    # Public: The GitHub controller for handling all incoming requests and determining
    # what validator that should be utilized.
    class GithubController < ApplicationController
      # POST /webhooks
      def validate
        return unless pull_request? || check_run?

        client_api = ::GithubBot::Github::Client.instance

        client_api.repository_pull_request_bots.each do |bot_class|
          clazz =
            begin
              bot_class.constantize
            rescue StandardError => e
              Rails.logger.error(
                message: "#{self.class}##{__method__} Pull request validator '#{bot_class}' is not defined",
                exception: e
              )

              nil
            end

          clazz&.validate
        end
      rescue StandardError => e
        Rails.logger.error message: 'GitHub Bot failure', exception: e
      end
    end
  end
end
