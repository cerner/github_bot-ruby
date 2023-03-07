# frozen_string_literal: true

require 'spec_helper'
require 'timecop'

RSpec.describe GithubBot::Github::CheckRun do
  let(:client) { double }

  subject do
    described_class.new(
      name: 'foo',
      repo: 'bar',
      sha: 'baz',
      client_api: client
    )
  end

  before :each do
    expect(client).to receive(:create_check_run)
  end

  it '#initialize' do
    expect(subject).not_to be_nil
  end

  it '#in_progress!' do
    time = Time.iso8601('2020-04-21T00:00:00Z')
    Timecop.freeze(time) do
      expect(subject).to receive(:update).with(status: 'in_progress', started_at: time)
      subject.in_progress!
    end
  end

  it '#complete!' do
    time = Time.iso8601('2020-04-21T00:00:00Z')
    Timecop.freeze(time) do
      expect(subject).to receive(:update).with(
        status: 'completed',
        conclusion: 'success',
        completed_at: time
      )
      subject.complete!
    end
  end

  it '#action_required!' do
    time = Time.iso8601('2020-04-21T00:00:00Z')
    Timecop.freeze(time) do
      expect(subject).to receive(:update).with(
        status: 'completed',
        conclusion: 'action_required',
        completed_at: time
      )
      subject.action_required!
    end
  end

  it '#neutral!' do
    time = Time.iso8601('2020-04-21T00:00:00Z')
    Timecop.freeze(time) do
      expect(subject).to receive(:update).with(
        status: 'completed',
        conclusion: 'neutral',
        completed_at: time
      )
      subject.neutral!
    end
  end
end
