require 'spec_helper'
require 'sqs_worker/manager'

module SqsWorker
  describe Manager do

    let(:worker_class) { StubWorker }

    subject(:manager) { described_class.new(worker_class) }
    subject(:worker_config) { double(WorkerConfig, num_processors: 10, num_fetchers: 2, num_batchers: 2, num_deleters: 2, queue_name: 'test-queue', empty_queue_throttle: 10) }

    before do
      expect(WorkerConfig).to receive(:new).with(worker_class).and_return(worker_config)
    end

    describe 'initialization' do

      before do
        # manager
      end

      it 'configures the processor pool' do
        # expect(Processor).to receive(:pool).with(size: worker_config.num_processors, args: worker_class)
      end

    end

  end
end

class StubWorker; end