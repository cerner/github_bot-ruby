# GitHub Bot

[![Cerner OSS](https://badgen.net/badge/Cerner/OSS/blue)](http://engineering.cerner.com/2014/01/cerner-and-open-source/)
[![License](https://badgen.net/github/license/cerner/github_bot-ruby)](https://github.com/cerner/github_bot-ruby/blob/main/LICENSE)
[![Build Status](https://github.com/cerner/github_bot-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/cerner/github_bot-ruby/actions/workflows/ci.yml)

This library is a ruby implementation necessary for beginning your GitHub bot development for Ruby-based projects. The key items this project provides to consumers are the following:

* Generic or application specific webhook mounted routes
* Octokit API configuration via Railtie
* Base classes for both your tasks and validators

See [wiki](https://github.com/cerner/github_bot-ruby/wiki) for more details.

# Building
This project is built using Ruby 2.6+, Rake and Bundler. RSpec is used for unit tests and SimpleCov
is utilized for test coverage. RuboCop is used to monitor the lint and style.

## Setup

To setup the development workspace, run the following after checkout:

    gem install bundler
    bundle install

## Tests

To run the RSpec tests, run the following:

    bin/rspec

## Lint

To analyze the project's style and lint, run the following:

    bin/rubocop

## Bundler Audit

To analyze the project's dependency vulnerabilities, run the following:

    bin/bundle audit

# Availability

This RubyGem will be available on https://rubygems.org/.

# Communication

All questions, bugs, enhancements and pull requests can be submitted here, on GitHub via Issues.

# Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

Copyright 2021 Cerner Innovation, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

&nbsp;&nbsp;&nbsp;&nbsp;http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Code of Conduct

Everyone interacting in the GithubBot project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
