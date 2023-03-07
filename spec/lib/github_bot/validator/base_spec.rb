# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GithubBot::Validator::Base do
  let(:client_api) { double }
  let(:check_run) { double }
  let(:warning_feedback) do
    {
      path: '/foo/bar.rb',
      annotation_level: 'warning',
      message: 'this is my warning annotation'
    }
  end
  let(:failure_feedback) do
    {
      path: '/bing/baz.rb',
      annotation_level: 'failure',
      message: 'this is my failure annotation'
    }
  end

  subject { described_class.new }

  before do
    allow(subject).to receive(:client_api).and_return(client_api)
  end

  describe '#check_run' do
    context 'when feedback empty' do
      it 'completes' do
        expect(client_api).to receive(:create_check_run).and_return(check_run)
        expect(check_run).to receive(:complete!)
        expect { subject.check_run(name: 'foo') }.not_to raise_error
      end
    end

    context 'when feedback warnings' do
      before do
        subject.instance_variable_set(:@feedback, [warning_feedback])
      end

      it 'gives a neutral check response' do
        expect(client_api).to receive(:create_check_run).and_return(check_run)
        expect(check_run).to receive(:neutral!)
        expect { subject.check_run(name: 'bar') }.not_to raise_error
      end
    end

    context 'when feedback failures' do
      before do
        subject.instance_variable_set(:@feedback, [failure_feedback])
      end

      it 'gives a needs attention response' do
        expect(client_api).to receive(:create_check_run).and_return(check_run)
        expect(check_run).to receive(:action_required!)
        expect { subject.check_run(name: 'baz') }.not_to raise_error
      end
    end
  end
end
