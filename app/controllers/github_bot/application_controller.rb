# frozen_string_literal: true

require 'json'
require_relative 'concerns/response'

module GithubBot
  # Public: Base controller for handing rails routes into the GithubBot
  class ApplicationController < ActionController::API
    include Response
    include GithubRequestHelper

    before_action :valid_request?
    before_action :event_processing

    # Public: Initial the request for event processing
    def event_processing
      Github::Client.initialize(request)
    end

    # Public: Returns <true> if the incoming request if properly authorized
    def valid_request?
      signature = github_signature
      my_signature = 'sha1=' + OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha1'),
        ENV['GITHUB_WEBHOOK_SECRET'],
        github_payload_raw
      )

      json_response(json_access_denied, :unauthorized) unless Rack::Utils.secure_compare(my_signature, signature)
    rescue StandardError => e
      msg = "#{self.class}##{__method__} An error occurred while determine if request is valid"
      Rails.logger.error(
        message: msg,
        exception: e
      )

      json_response(json_access_denied(errors: { message: "#{msg}, exception: #{e.message}" }), :unauthorized)
    end
  end
end
