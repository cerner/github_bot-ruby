# frozen_string_literal: true

require 'spec_helper'

class DummyTestClass
  include GithubBot::Github::Payload

  def repository; end
end

RSpec.describe GithubBot::Github::Payload do
  subject { DummyTestClass.new }

  describe '#repository_fork_urls' do
    let(:mock_payload) { double }
    let(:mock_repository) { double }
    let(:mock_parse) { double('URI::HTTP', query: []) }
    let(:mock_open) { double }
    let(:mock_data) do
      [].tap do |ar|
        ar << {
          updated_at: '2020-10-01T00:00:00Z',
          clone_url: 'http://foo.clone.com'
        }.with_indifferent_access

        ar << {
          updated_at: '2020-10-02T00:00:00Z',
          clone_url: 'http://bar.clone.com'
        }.with_indifferent_access
      end
    end

    before do
    end

    it 'returns fork urls' do
      allow(URI).to receive(:parse).and_return(mock_parse)
      allow(mock_parse).to receive(:query=)
      allow(mock_parse).to receive(:open).and_return(mock_open)
      allow(mock_open).to receive(:read)
      allow(subject).to receive(:repository).and_return(mock_repository)
      allow(subject).to receive(:payload).and_return(mock_payload)

      # first sequence expect to retrieve actual data, second time return empty response
      expect(JSON).to receive(:parse).ordered.and_return(mock_data)
      expect(JSON).to receive(:parse).ordered.and_return({})

      expect(mock_repository).to receive(:[]).with(:forks_url)
      urls = subject.repository_fork_urls
      expect(urls.length).to be 2
      expect(urls).to include('http://bar.clone.com')
    end
  end
end
