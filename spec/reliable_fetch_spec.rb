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

    it 'moves a job to its working queue without the deprecated RPOPLPUSH command' do
      job = Sidekiq.dump_json(class: 'Bob', args: [1])
      Sidekiq.redis { |conn| conn.rpush('queue:default', job) }

      work = nil
      expect { work = fetcher.retrieve_work }.not_to output(/deprecated/).to_stderr

      expect(work.job).to eq(job)
      working_queue = described_class.working_queue_name('queue:default')
      expect(Sidekiq.redis { |conn| conn.lrange(working_queue, 0, -1) }).to eq([job])
    end

    it 'waits one second before polling again after an empty queue scan' do
      expect(fetcher).to receive(:sleep).with(1)

      expect(fetcher.retrieve_work).to be_nil
    end
  end
end
