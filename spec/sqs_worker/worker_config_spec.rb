require 'spec_helper'
require 'sqs_worker/worker_config'

module SqsWorker
  describe WorkerConfig do

    subject(:worker_config) { described_class.new(config) }

    context 'with simple configuration' do

      let(:config) do
        {
          queue_name: 'queue',
          processors: 30,
          empty_queue_throttle: 5
        }
      end

      it 'sets queue name' do
        expect(worker_config.queue_name).to eq config[:queue_name]
      end

      it 'sets empty queue throttle' do
        expect(worker_config.empty_queue_throttle).to eq config[:empty_queue_throttle]
      end

      it 'sets the number of processors' do
        expect(worker_config.num_processors).to eq config[:processors]
      end

      it 'sets the number of fetchers to the optimal size' do
        expect(worker_config.num_fetchers).to eq(config[:processors] / Fetcher::MESSAGE_FETCH_LIMIT)
      end

      it 'sets the number of batchers to the optimal size' do
        expect(worker_config.num_batchers).to eq(config[:processors] / Fetcher::MESSAGE_FETCH_LIMIT)
      end

      it 'sets the number of deleters to the optimal size' do
        expect(worker_config.num_deleters).to eq(config[:processors] / Fetcher::MESSAGE_FETCH_LIMIT)
      end

    end

    context 'with number of processors less than minimum' do

      let(:config) do
        {
          queue_name: 'queue',
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

    context 'with missing and defaultable configuration' do

      let(:config) do
        {
          queue_name: 'queue'
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

end
