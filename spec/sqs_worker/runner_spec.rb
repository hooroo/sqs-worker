require 'spec_helper'
require 'sqs_worker/runner'

module SqsWorker
  describe Runner do

    describe '#run_all' do

      let(:read_io) { double(IO) }
      let(:write_io) { double(IO) }
      let(:worker_resolver) { WorkerResolver.new }
      let(:worker_class_a) { double(Class) }
      let(:worker_class_b) { double(Class) }
      let(:worker_classes) { [worker_class_a, worker_class_b] }
      let(:manager_a) { double(Manager, worker_class: worker_class_a) }
      let(:manager_b) { double(Manager, worker_class: worker_class_b) }
      let(:logger) { double('logger', info: nil) }

      before do
        SqsWorker.logger = logger
        expect(IO).to receive(:pipe).and_return [read_io, write_io]
        expect(IO).to receive(:select).with([read_io])
        expect(WorkerResolver).to receive(:new).and_return worker_resolver
      end

      after do
        SqsWorker.logger = nil
      end

      it 'traps signals' do
        expect(worker_resolver).to receive(:resolve_worker_classes).and_return []

        ['SIGTERM', 'TERM', 'SIGINT'].each do |signal|
          expect(Signal).to receive(:trap).with(signal).and_yield
          expect(write_io).to receive(:puts).with(signal)
        end

        Runner.run_all
      end


      it 'starts and shuts down managers on receipt of signal' do

        expect(worker_resolver).to receive(:resolve_worker_classes).and_return worker_classes

        expect(Manager).to receive(:new).with(worker_class_a).and_return(manager_a)
        expect(Manager).to receive(:new).with(worker_class_b).and_return(manager_b)

        expect(manager_a).to receive(:start)
        expect(manager_b).to receive(:start)

        expect(manager_a).to receive(:prepare_for_shutdown)
        expect(manager_b).to receive(:prepare_for_shutdown)

        # Test that we keep asking until managers have stopped running
        # This set of interactions are dependent on the order of the
        # managers in the array as it fails fast on testing if any are running.
        expect(manager_a).to receive(:running?).once.and_return(true)
        expect(manager_a).to receive(:running?).once.and_return(false)
        expect(manager_b).to receive(:running?).and_return(false)

        expect(logger).to receive(:info).with(event_name: 'sqs_worker_shutdown_complete', type: manager_a.worker_class)
        expect(logger).to receive(:info).with(event_name: 'sqs_worker_shutdown_complete', type: manager_b.worker_class)

        expect(manager_a).to receive(:terminate)
        expect(manager_b).to receive(:terminate)

        Runner.run_all
      end

    end

  end
end
