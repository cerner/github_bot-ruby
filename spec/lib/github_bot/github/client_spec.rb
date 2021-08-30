# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GithubBot::Github::Client do
  let(:request) { double }
  let(:client) { double }
  let(:removed_file) { double('Sawyer::Resource', type: 'file', status: 'removed') }
  let(:added_file) { double('Sawyer::Resource', type: 'file', status: 'added') }
  let(:files) { [removed_file, added_file] }
  let(:pull_request) { double }

  subject { described_class.initialize(request) }

  before :each do
    described_class.instance_variable_set(:@instance, nil)
    subject.instance_variable_set(:@client, client)
  end

  it '.initialize' do
    expect(described_class.initialize(request)).not_to be_nil
  end

  describe '.instance' do
    before :each do
      described_class.instance_variable_set(:@instance, nil)
    end

    context 'when no instance' do
      it 'raises error' do
        expect { described_class.instance }.to raise_error(StandardError)
      end
    end

    context 'when an instance exists' do
      let(:instance) { double }
      it 'returns the instance' do
        described_class.instance_variable_set(:@instance, instance)
        expect(described_class.instance).to eql(instance)
      end
    end
  end

  describe '#file_content' do
    let(:file) { double('Sawyer::Resource', type: 'file') }
    let(:filename) { 'foo' }

    before do
      allow(file).to receive(:filename).and_return(filename)
      allow(subject).to receive(:repository_full_name)
      allow(subject).to receive(:head_sha)
    end

    context 'when content not found' do
      it 'returns empty string' do
        expect(client).to receive(:contents).and_raise(Octokit::NotFound)
        expect(subject.file_content(file)).to be_empty
      end
    end

    context 'when content found' do
      context 'when small' do
        it 'decodes the response' do
          expect(client).to receive(:contents)
          expect { subject.file_content(file) }.not_to raise_error
        end
      end

      context 'when too_large' do
        let(:exception) { Octokit::Forbidden.new(body: { errors: [code: 'too_large'] }) }
        let(:uri_object) { double }
        let(:raw_url) { 'https://raw.github.com/foo/bar/main/file.rb'}
        let(:parsed_url) { double }

        it 'uses the raw url for retrieval' do
          expect(client).to receive(:contents).and_raise(exception)
          expect(file).to receive(:raw_url).and_return(raw_url)
          expect(URI).to receive(:parse).with(raw_url).and_return(parsed_url)
          expect(parsed_url).to receive(:open).and_return(uri_object)
          expect(uri_object).to receive(:read)
          expect { subject.file_content(file) }.not_to raise_error
        end
      end
    end
  end

  describe '#modified_files' do
    it 'returns modified files' do
      allow(subject).to receive(:pull_request).and_return(pull_request)
      expect(subject).to receive(:repository_full_name)
      expect(subject).to receive(:pull_request_number)
      expect(client).to receive(:pull_request_files).and_return(files)
      expect(subject.modified_files).not_to be_empty
      expect(subject.modified_files).to include(added_file)
      expect(subject.modified_files).not_to include(removed_file)
    end
  end

  describe '#files' do
    it 'returns all files' do
      allow(subject).to receive(:pull_request).and_return(pull_request)
      expect(subject).to receive(:repository_full_name)
      expect(subject).to receive(:pull_request_number)
      expect(client).to receive(:pull_request_files).and_return(files)
      expect(subject.files).not_to be_empty
      expect(subject.files).to include(added_file)
      expect(subject.files).to include(removed_file)
    end
  end

  describe '#comment' do
    it 'adds a comment' do
      expect(subject).to receive(:repository_full_name)
      expect(subject).to receive(:pull_request_number)
      expect(client).to receive(:add_comment)
      subject.comment(message: 'foo')
    end
  end

  describe '#create_check_run' do
    it 'creates a check run instance' do
      expect(subject).to receive(:repository_full_name)
      expect(subject).to receive(:head_sha)
      expect(GithubBot::Github::CheckRun).to receive(:new)
      subject.create_check_run(name: 'foo')
    end
  end

  describe '#pull_request_details' do
    let(:repo_name) { 'foo-delivery/foo-config' }
    let(:pull_request_number) { 123 }
    let(:pull_request) { { number: pull_request_number } }
    let(:pull_request_response) { double }
    let(:mock_payload) do
      {
        repository: {
          full_name: repo_name
        }
      }
    end

    it 'validates' do
      allow(subject).to receive(:payload).and_return(mock_payload)
      expect(subject).to receive(:pull_request).and_return(pull_request)
      expect(client).to receive(:pull_request).with(
        repo_name, pull_request_number
      ).and_return(pull_request_response)
      expect(subject.pull_request_details).to eq(pull_request_response)

      # check set of instance variable
      expect(subject.instance_variable_get(:@pull_request_details)).to eq(pull_request_response)
      expect(client).not_to receive(:pull_request)
      expect(subject.pull_request_details).to eq(pull_request_response)
    end
  end
end