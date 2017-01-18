require 'spec_helper'
require 'sqs_worker/runner'
require 'sqs_worker/heartbeat/log_file_heartbeat_monitor'

module SqsWorker
  describe Runner do

    describe '#run_all' do

      subject(:runner) { described_class.new }

      let(:signals_received) { [] }
      let(:worker_resolver) { WorkerResolver.new }
      let(:worker_class_a) { double(Class) }
      let(:worker_class_b) { double(Class) }
      let(:worker_classes) { [worker_class_a, worker_class_b] }
      let(:manager_a_running) { false }
      let(:manager_b_running) { false }
      let(:manager_a) do
        instance_double(Manager,
          worker_class: worker_class_a,
          prepare_to_start: nil,
          start: nil,
          prepare_for_shutdown: nil,
          running?: manager_a_running,
          terminate: nil,
          soft_stop: nil,
          soft_start: nil
        )
      end

      let(:manager_b) do
        instance_double(Manager,
          worker_class: worker_class_b,
          prepare_to_start: nil,
          start: nil,
          prepare_for_shutdown: nil,
          running?: manager_b_running,
          terminate: nil,
          soft_stop: nil,
          soft_start: nil
        )
      end

      let(:heartbeat_monitor) do
        double(Heartbeat::LogFileHeartbeatMonitor)
      end

      let(:logger)            { double('logger', info: nil) }
      let(:heartbeat_logger)  { double('heartbeat logger', info: nil) }

      before do
        SqsWorker.logger = logger
        SqsWorker.heartbeat_logger = heartbeat_logger
        allow(WorkerResolver).to receive(:new).and_return worker_resolver
        allow(worker_resolver).to receive(:resolve_worker_classes).and_return worker_classes
        runner.instance_variable_set('@signals', signals_received)

        allow(Heartbeat::LogFileHeartbeatMonitor).to receive(:new).with(logger: heartbeat_logger, threshold_seconds: 60).and_return(heartbeat_monitor)
        allow(Manager).to receive(:new).with(worker_class: worker_class_a, heartbeat_monitor: heartbeat_monitor).and_return(manager_a)
        allow(Manager).to receive(:new).with(worker_class: worker_class_b, heartbeat_monitor: heartbeat_monitor).and_return(manager_b)
      end

      after do
        SqsWorker.logger = nil
      end

      describe 'Signal trapping' do
        # Ensures the process exits instead of getting stuck in a loop
        let(:signals_received) { ['TERM'] }

        it 'traps signals' do
          expect(worker_resolver).to receive(:resolve_worker_classes).and_return([])

          ['TERM', 'INT', 'USR1', 'USR2'].each do |signal|
            expect(Signal).to receive(:trap).with(signal)
          end

          expect(runner).to receive(:exit)

          runner.run_all
        end
      end

      describe 'behaviour upon receiving signals' do
        before do
          allow(runner).to receive(:exit)
          allow(manager_a).to receive(:running?).and_return(*manager_running)

          runner.run_all
        end

        let(:manager_running) { [manager_a_running] }

        describe 'SIGUSR1' do
          let(:signals_received) { ['USR1', 'TERM'] }


          it 'softly stops managers' do
            expect(manager_a).to have_received(:soft_stop)
            expect(manager_b).to have_received(:soft_stop)
          end

          it 'logs a message when managers have stopped' do
            expect(logger).to have_received(:info).with(event_name: 'sqs_worker_soft_stop_complete', type: 'SqsWorker::Runner')
          end

          context 'when the manager takes a while to stop' do
            let(:manager_running) do
              [true, true, false]
            end
            it 'logs a message when managers are still running' do
              expect(logger).to have_received(:info).with(event_name: 'sqs_worker_still_running', type: manager_a.worker_class).
              exactly(2).times
            end
          end
        end

        describe 'SIGUSR2' do
          let(:signals_received) { ['USR1', 'USR2', 'TERM'] }

          it 'softly starts managers' do
            expect(manager_a).to have_received(:soft_start)
            expect(manager_b).to have_received(:soft_start)
          end
        end

        describe 'SIGTERM' do
          let(:signals_received) { ['TERM'] }

          it 'prepares the managers for shutdown' do
            expect(manager_a).to have_received(:prepare_for_shutdown)
            expect(manager_b).to have_received(:prepare_for_shutdown)
          end

          it 'logs a message per manager when it has completed the shutdown process' do
            expect(logger).to have_received(:info).with(event_name: 'sqs_worker_shutdown_complete', type: manager_a.worker_class)
            expect(logger).to have_received(:info).with(event_name: 'sqs_worker_shutdown_complete', type: manager_b.worker_class)
          end

          it 'terminates the managers' do
            expect(manager_a).to have_received(:terminate)
            expect(manager_b).to have_received(:terminate)
          end

          it 'terminates the runner' do
            expect(runner).to have_received(:exit)
          end

        end

      end

    end

  end
end