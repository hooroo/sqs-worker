require 'spec_helper'
require 'sqs_worker/manager'

module SqsWorker
  describe Manager do

    subject(:manager) { described_class.new(worker_class) }

    let(:worker_class) { StubWorker }
    let(:worker_config) do
      double(WorkerConfig, {
        num_processors: 10,
        num_fetchers: 2,
        num_batchers: 2,
        num_deleters: 2,
        queue_name: 'test-queue',
        empty_queue_throttle: 10,
        fetcher_batch_size: 5
      })
    end

    let(:processor) { double(Processor) }
    let(:processor_pool) { double('processor', async: processor, publish: true ) }

    let(:fetcher) { double(Fetcher, fetch: nil) }
    let(:fetcher_pool) { double('fetcher', async: fetcher, size: worker_config.num_fetchers ) }

    let(:deleter) { double(Deleter) }
    let(:deleter_pool) { double('deleter', async: deleter ) }

    let(:batcher) { double(Batcher) }
    let(:batcher_pool) { double('batcher', async: batcher, publish: true ) }

    let(:logger) { double('logger', info: nil) }

    before do
      SqsWorker.logger = logger
      allow(StubWorker).to receive(:config).and_return(worker_config)
      allow(Processor).to receive(:pool).with(size: worker_config.num_processors, args: worker_class).and_return(processor_pool)
      allow(Fetcher).to receive(:pool).with(size: worker_config.num_fetchers, args: [{ queue_name: worker_config.queue_name, manager: Manager, batch_size: worker_config.fetcher_batch_size }]).and_return(fetcher_pool)
      allow(Deleter).to receive(:pool).with(size: worker_config.num_deleters, args: [worker_config.queue_name]).and_return(deleter_pool)
      allow(Batcher).to receive(:pool).with(size: worker_config.num_batchers, args: [{ manager: Manager, processor: processor_pool }]).and_return(batcher_pool)
      manager
    end

    after do
      SqsWorker.logger = nil
    end

    context 'while not shutting down' do

      describe '#fetch_messages / start' do

        it 'fetches messages based on number of fetchers' do
          expect(fetcher).to receive(:fetch).exactly(fetcher_pool.size).times
          manager.start
        end

        it 'logs start' do
          expect(logger).to receive(:info).with(event_name: 'sqs_worker_starting_manager', type: worker_class, queue_name: worker_class.config.queue_name)
          manager.start
        end
      end

      describe '#fetch_done(messages)' do

        it 'processes the message' do
          expect(batcher).to receive(:process).once
          manager.fetch_done([])
        end
      end
    end

    context 'while shutting down' do

      before do
        manager.shutting_down(nil)
      end

      describe '#fetch_messages / start' do

        it 'does not fetch any new messages' do
          expect(fetcher).to_not receive(:fetch)
          manager.start
        end
      end

      describe '#fetch_done(messages)' do

        it 'processes the message' do
          expect(batcher).to_not receive(:process)
          manager.fetch_done([])
        end
      end
    end

    describe '#batch_done(messages)' do

      let(:messages) { [] }

      it 'deletes the messages and fetches messages once' do
        expect(deleter).to receive(:delete).with(messages).once
        expect(fetcher).to receive(:fetch).once
        manager.batch_done(messages)
      end
    end

    describe '#running?' do

      let(:deleter_pool) { double('deleter', busy_size: 0 ) }
      let(:batcher_pool) { double('batcher', busy_size: 0 ) }

      before do
        manager.shutting_down(nil)
      end

      specify "when shutting down and the deleter isn't busy and the batcher isn't busy" do
        expect(manager.running?).to be false
      end

      context 'when not shutting down' do
        it 'returns true' do
          manager.starting(nil)
          expect(manager.running?).to be true
        end
      end

      context 'when the deleter is busy' do

        let(:deleter_pool) { double('deleter', busy_size: 1 ) }

        it 'returns true' do
          expect(manager.running?).to be true
        end
      end

      context 'when the batcher is busy' do

        let(:batcher_pool) { double('batcher', busy_size: 1 ) }

        it 'returns true' do
          expect(manager.running?).to be true
        end
      end
    end

    describe '#prepare_for_shutdown' do
      it 'sends a signal to itself, batcher and processor' do
        expect(batcher_pool).to receive(:publish).with('SIGTERM')
        expect(processor_pool).to receive(:publish).with('SIGTERM')
        expect(logger).to receive(:info).with(event_name: 'sqs_worker_prepare_for_shutdown', type: worker_class, queue_name: worker_class.config.queue_name)
        manager.prepare_for_shutdown
        expect(manager.shutting_down?).to be true
      end
    end

    describe '#soft_stop' do
      it 'sends a signal to itself, batcher and processor' do
        expect(batcher_pool).to receive(:publish).with('SIGUSR1')
        expect(processor_pool).to receive(:publish).with('SIGUSR1')
        expect(logger).to receive(:info).with(event_name: 'sqs_worker_soft_stop', type: worker_class, queue_name: worker_class.config.queue_name)
        manager.soft_stop
        expect(manager.stopping?).to be true
      end
    end

    describe '#soft_start' do
      it 'sends a signal to itself, batcher and processor' do
        manager.soft_stop
        expect(batcher_pool).to receive(:publish).with('SIGUSR2')
        expect(processor_pool).to receive(:publish).with('SIGUSR2')
        expect(logger).to receive(:info).with(event_name: 'sqs_worker_soft_start', type: worker_class, queue_name: worker_class.config.queue_name)
        manager.soft_start
        expect(manager.stopping?).to be false
      end
    end
  end
end

class StubWorker

  def self.config
    OpenStruct.new(queue_name: 'queue_name')
  end

end
