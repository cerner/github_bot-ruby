# frozen_string_literal: true

GithubBot::Engine.routes.draw do
  namespace :webhooks do
    post '/', action: :validate, controller: 'github', defaults: { format: :json }
  end
end

# Adding this to mount the above routes into the application level in order to be able to use
# the path helpers without having to access them with the main_app.
Rails.application.routes.draw do
  mount GithubBot::Engine => '/' if GithubBot.draw_routes_in_host_app
end
