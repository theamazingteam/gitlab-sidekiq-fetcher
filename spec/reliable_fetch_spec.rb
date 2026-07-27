require 'spec_helper'
require 'fetch_shared_examples'
require 'sidekiq/base_reliable_fetch'
require 'sidekiq/reliable_fetch'
require 'sidekiq/capsule'

describe Sidekiq::ReliableFetch do
  include_examples 'a Sidekiq fetcher'

  describe '#retrieve_work' do
    let(:config) { Sidekiq::Config.new(queues: ['default']) }
    let(:capsule) { Sidekiq::Capsule.new('default', config) }
    let(:fetcher) { described_class.new(capsule) }

    before do
      config.queues = ['default']
      Sidekiq.redis(&:flushdb)
    end

    it 'waits one second before polling again after an empty queue scan' do
      expect(fetcher).to receive(:sleep).with(1)

      expect(fetcher.retrieve_work).to be_nil
    end
  end
end
