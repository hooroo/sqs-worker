require 'spec_helper'
require 'sqs_worker/manager'

module SqsWorker
  describe Manager do

    let(:worker_class) { UnitStubWorker }
    let(:worker_config) do
      instance_double(WorkerConfig,
                      num_processors:       10,
                      num_fetchers:         2,
                      num_batchers:         2,
                      num_deleters:         2,
                      queue_name:           queue_name,
                      empty_queue_throttle: 10,
                      fetcher_batch_size:   5
      )
    end

    let(:sqs_instance)    { double(SqsWorker::Sqs) }
    let(:queue_name)      { 'test-queue' }

    let(:processor)       { double(Processor) }
    let(:processor_pool)  { double('processor', async: processor, publish: true) }

    let(:fetcher)         { double(Fetcher, fetch: nil) }
    let(:fetcher_pool)    { double('fetcher', async: fetcher, size: worker_config.num_fetchers) }

    let(:deleter)         { double(Deleter) }
    let(:deleter_pool)    { double('deleter', async: deleter) }

    let(:batcher)         { double(Batcher) }
    let(:batcher_pool)    { double('batcher', async: batcher, publish: true) }

    let(:heartbeat_monitor) { double('heartbeat') }

    subject(:manager) { described_class.new(worker_class: worker_class, heartbeat_monitor: heartbeat_monitor) }

    before do
      allow(SqsWorker::Sqs).to receive(:instance).and_return(sqs_instance)
      allow(sqs_instance).to receive(:find_queue).with(queue_name)
      allow(UnitStubWorker).to receive(:config).and_return(worker_config)
      allow(Processor).to receive(:pool).with(size: worker_config.num_processors, args: worker_class).and_return(processor_pool)
      allow(Fetcher).to receive(:pool).with(size: worker_config.num_fetchers, args: [{ queue_name: worker_config.queue_name, manager: Manager, batch_size: worker_config.fetcher_batch_size }]).and_return(fetcher_pool)
      allow(Deleter).to receive(:pool).with(size: worker_config.num_deleters, args: [worker_config.queue_name]).and_return(deleter_pool)
      allow(Batcher).to receive(:pool).with(size: worker_config.num_batchers, args: [{ manager: Manager, processor: processor_pool }]).and_return(batcher_pool)
      allow(heartbeat_monitor).to receive(:tick)
    end

    context 'while not shutting down' do

      describe '#prepare_to_start' do

        before do
          allow(SqsWorker).to receive(:shutdown).and_return(nil)
        end

        context 'when the queue exists' do

          it 'does not raise an error' do
            expect { manager.prepare_to_start }.to_not raise_error
          end
        end

        context 'when the queue does not exist' do

          before do
            allow(sqs_instance).to receive(:find_queue).with(queue_name).and_raise(SqsWorker::Errors::NonExistentQueue)
          end

          it 'logs that the queue was not found' do
            expect(logger).to receive(:info).with(event_name: 'sqs_worker_queue_not_found', type: worker_class, queue_name: worker_class.config.queue_name)
            expect { manager.prepare_to_start }.to raise_error(SqsWorker::Errors::NonExistentQueue)
          end

          it 're-raises the error' do
            expect { manager.prepare_to_start }.to raise_error(SqsWorker::Errors::NonExistentQueue)
          end
        end
      end

      describe '#start' do

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
        before do
          allow(batcher).to receive(:process).once
          manager.fetch_done([])
        end

        it 'processes the message' do
          expect(batcher).to have_received(:process).once
        end

        it 'sends a tick to the heartbeat monitor' do
          expect(heartbeat_monitor).to have_received(:tick).once
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

    describe '#handle_unrecoverable_error(signal, worker_class)' do
      let(:signal) { double }
      
      subject(:handle_unrecoverable_error) { manager.handle_unrecoverable_error(signal, originating_worker_class) }

      before do
        handle_unrecoverable_error
      end

      context "when the signal originates it's worker class" do
        let(:originating_worker_class) { worker_class }

        it 'does not signal the manager to shut down' do
          expect(manager.stopping?).to eq(true)
        end
      end

      context "when the signal does not originate from  it's worker class" do
        let(:originating_worker_class) { SomeOtherWorkerClass = Struct.new(:method) }

        it 'signals the manager to shut down' do
          expect(manager.stopping?).to eq(false)
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
      let(:deleter_pool) { double('deleter', busy_size: 0) }
      let(:batcher_pool) { double('batcher', busy_size: 0) }

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
        let(:deleter_pool) { double('deleter', busy_size: 1) }

        it 'returns true' do
          expect(manager.running?).to be true
        end
      end

      context 'when the batcher is busy' do
        let(:batcher_pool) { double('batcher', busy_size: 1) }

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

class UnitStubWorker
  def self.config
    OpenStruct.new(queue_name: 'queue_name')
  end
end
