require 'spec_helper'
require 'sqs_worker/worker_config'

module SqsWorker
  describe WorkerConfig do

    subject(:worker_config) { described_class.new(config) }

    let(:config) do
      {
        queue_name: queue_name,
        processors: 20,
        empty_queue_throttle: 5
      }
    end

    let(:queue_name) { 'queue-me-up' }
    let(:logger) { double('logger', debug: nil) }

    before do
      SqsWorker.logger = logger
    end

    context 'when the queue exists' do

      before do
        allow(Sqs.instance).to receive(:find_queue).with(queue_name)
      end

      context 'with simple configuration' do

        it 'sets queue name' do
          expect(worker_config.queue_name).to eq config[:queue_name]
        end

        it 'sets empty queue throttle' do
          expect(worker_config.empty_queue_throttle).to eq config[:empty_queue_throttle]
        end

        it 'sets the number of processors' do
          expect(worker_config.num_processors).to eq config[:processors]
        end

        it 'sets the fetcher batch size to the correct size' do
          expect(worker_config.fetcher_batch_size).to eq(config[:processors] / worker_config.num_fetchers)
        end

        it 'sets the number of fetchers to the correct size' do
          expect(worker_config.num_fetchers).to eq(WorkerConfig::MIN_POOL_SIZE)
        end

        it 'sets the number of batchers to the optimal size' do
          expect(worker_config.num_batchers).to eq(WorkerConfig::MIN_POOL_SIZE)
        end

        it 'sets the number of deleters to the optimal size' do
          expect(worker_config.num_deleters).to eq(WorkerConfig::MIN_POOL_SIZE)
        end

      end

      context 'with number of processors less than minimum' do

        let(:config) do
          {
            queue_name: queue_name,
            empty_queue_throttle: 5,
            processors: WorkerConfig::MIN_PROCESSORS - 1
          }
        end

        it 'sets the number of processors to the minimum' do
          expect(worker_config.num_processors).to eq WorkerConfig::MIN_PROCESSORS
        end

        it 'sets the number of fetchers to the minimum pool size' do
          expect(worker_config.num_fetchers).to eq(WorkerConfig::MIN_POOL_SIZE)
        end

        it 'sets the number of batchers to the minimum pool size' do
          expect(worker_config.num_batchers).to eq(WorkerConfig::MIN_POOL_SIZE)
        end

        it 'sets the number of deleters to the minimum pool size' do
          expect(worker_config.num_deleters).to eq(WorkerConfig::MIN_POOL_SIZE)
        end

      end

      context 'with number of processors that maxes out the fetch batch size' do

        let(:num_processors) { WorkerConfig::MAX_FETCH_BATCH_SIZE * WorkerConfig::MIN_POOL_SIZE + 1 }

        let(:config) do
          {
            queue_name: queue_name,
            empty_queue_throttle: 5,
            processors: num_processors
          }
        end

        it 'sets the number of processors to the configured amount' do
          expect(worker_config.num_processors).to eq num_processors
        end

        it 'sets the fetcher batch size to the maximum allowable size (defined by aws-sdk)' do
          expect(worker_config.fetcher_batch_size).to eq(WorkerConfig::MAX_FETCH_BATCH_SIZE)
        end

      end

      context 'with missing and defaultable configuration' do

        let(:config) do
          {
            queue_name: queue_name
          }
        end

        it 'sets the number of processors to the default' do
          expect(worker_config.num_processors).to eq WorkerConfig::MIN_PROCESSORS
        end

        it 'sets the number of fetchers to the minimum pool size' do
          expect(worker_config.num_fetchers).to eq(WorkerConfig::MIN_POOL_SIZE)
        end

        it 'sets the number of batchers to the minimum pool size' do
          expect(worker_config.num_batchers).to eq(WorkerConfig::MIN_POOL_SIZE)
        end

        it 'sets the number of deleters to the minimum pool size' do
          expect(worker_config.num_deleters).to eq(WorkerConfig::MIN_POOL_SIZE)
        end

        it 'sets the emoty_queue_throttle to the default' do
          expect(worker_config.empty_queue_throttle).to eq(WorkerConfig::DEFAULT_EMPTY_QUEUE_THROTTLE)
        end

      end

      context 'without a queue name' do

        let(:config) { {} }

        it 'raises error' do
          expect{ worker_config }.to raise_error
        end
      end
    end

    context 'when the queue does not exist' do

      # RSpec throws an error for some reason because the original logger has already been used
      let(:second_logger) { double('logger', debug: nil) }

      before do
        SqsWorker.logger = second_logger
      end

      it 'raises an error' do
        expect { worker_config }.to raise_error(SqsWorker::Errors::NonExistentQueue)
      end
    end

  end

end
