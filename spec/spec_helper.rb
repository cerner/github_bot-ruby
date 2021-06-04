# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'
require 'github_bot'

Dir.glob(File.join(File.dirname(__FILE__), 'support', '**/*.rb'), &method(:require))

SimpleCov.start do
  coverage_dir 'target/coverage'
  add_filter '/spec/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Libraries', 'lib'

  track_files '{app,config,lib}/**/*.rb'
end

require 'combustion'
if Rails.application.instance_of? Combustion::Application
  modules_list = %i[action_controller action_view]
  # Check if active_record should be initialized with Combustion.
  # Criteria : Engine should have a db/migrate folder with migrations
  modules_list << :active_record if File.exist?('db/migrate') && !Dir.empty?('db/migrate')

  Combustion.initialize!(*modules_list)
end

require 'rspec/rails'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.infer_spec_type_from_file_location!
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.example_status_persistence_file_path = 'build/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true
  config.include Rails.application.routes.url_helpers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end