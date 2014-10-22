require 'spec_helper'
require 'sqs_worker/manager'

module SqsWorker
  describe Manager do

    let(:worker_class) { StubWorker }

    subject(:manager) { described_class.new(worker_class) }
    subject(:worker_config) { double(WorkerConfig, num_processors: 10, num_fetchers: 2, num_batchers: 2, num_deleters: 2, queue_name: 'test-queue', empty_queue_throttle: 10) }

    let(:processor) { double(Processor) }
    let(:processor_pool) { double('processor', async: processor ) }

    let(:fetcher) { double(Fetcher) }
    let(:fetcher_pool) { double('fetcher', async: fetcher, size: worker_config.num_fetchers ) }

    let(:deleter) { double(Deleter) }
    let(:deleter_pool) { double('deleter', async: deleter ) }

    let(:batcher) { double(BatchProcessor) }
    let(:batcher_pool) { double('batcher', async: batcher ) }

    before do
      expect(WorkerConfig).to receive(:new).with(worker_class).and_return(worker_config)
      expect(Processor).to receive(:pool).with(size: worker_config.num_processors, args: worker_class).and_return(processor_pool)
      expect(Fetcher).to receive(:pool).with(size: worker_config.num_fetchers, args: [{ queue_name: worker_config.queue_name, configuration: SqsWorker.configuration, manager: Manager }]).and_return(fetcher_pool)
      expect(Deleter).to receive(:pool).with(size: worker_config.num_deleters, args: [{ queue_name: worker_config.queue_name, configuration: SqsWorker.configuration }]).and_return(deleter_pool)
      expect(BatchProcessor).to receive(:pool).with(size: worker_config.num_batchers, args: [{ manager: Manager, processor: processor_pool }]).and_return(batcher_pool)
      manager
    end


    context 'while not shutting down' do

      describe '#fetch_messages / bootstrap' do

        it 'fetches messages based on number of fetchers' do
          expect(fetcher).to receive(:fetch).exactly(fetcher_pool.size).times
          manager.bootstrap
        end
      end

      describe "#fetch_done(messages)" do

        it "processes the message" do
          expect(batcher).to receive(:process).once
          manager.fetch_done([])
        end
      end
    end

    context 'while shutting down' do

      before do
        manager.shutting_down(nil)
      end

      describe '#fetch_messages / bootstrap' do

        it 'does not fetch any new messages' do
          expect(fetcher).to_not receive(:fetch)
          manager.bootstrap
        end
      end

      describe "#fetch_done(messages)" do

        it "processes the message" do
          expect(batcher).to_not receive(:process)
          manager.fetch_done([])
        end
      end
    end

    describe "#batch_done(messages)" do

      let(:messages) { [] }

      it "deletes the messages and fetches messages once" do
        expect(deleter).to receive(:delete).with(messages).once
        expect(fetcher).to receive(:fetch).once
        manager.batch_done(messages)
      end
    end

    describe "#running?" do

      let(:deleter_pool) { double('deleter', busy_size: 0 ) }
      let(:batcher_pool) { double('batcher', busy_size: 0 ) }

      before do
        manager.instance_variable_set(:@shutting_down, true)
      end

      specify "when shutting down and the deleter isn't busy and the batcher isn't busy" do
        expect(manager.running?).to be false
      end

      context "when not shutting down" do

        it "returns true" do
          manager.instance_variable_set(:@shutting_down, false)
          expect(manager.running?).to be true
        end
      end

      context "when the deleter is busy" do

        let(:deleter_pool) { double('deleter', busy_size: 1 ) }

        it "returns true" do          
          expect(manager.running?).to be true
        end
      end

      context "when the batcher is busy" do

        let(:batcher_pool) { double('batcher', busy_size: 1 ) }

        it "returns true" do
          expect(manager.running?).to be true
        end
      end


    end

    # describe "#throttle" do

    #   context "when the queue is empty" do

    #     it "sets the throttle to the empty_queue_throttle value" do
    #       # manager.empty_queue = true
    #       manager.send(:empty_queue=, true) # dodgy?
    #       expect(manager.throttle).to eq(worker_config.empty_queue_throttle)
    #     end
    #   end

    #   context "when the queue is not empty" do

    #     it "sets the throttle to zero" do
    #       # manager.empty_queue = false
    #       manager.send(:empty_queue=, false) # dodgy?
    #       expect(manager.throttle).to eq(0)
    #     end
    #   end
    # end

  end
end

class StubWorker; end