require 'sqs_worker/manager'
require 'sqs_worker/worker_resolver'

module SqsWorker

  class Runner

    #Find all workers and start processing messages from their configured queues
    def self.run_all

      read_io, write_io = IO.pipe

      trap_signals(write_io)

      begin

        worker_classes = WorkerResolver.new.resolve_worker_classes

        managers = worker_classes.map { |worker_class| Manager.new(worker_class) }

        managers.each(&:start)

        on_signal_received(read_io) do

          managers.each(&:prepare_for_shutdown)

          while managers.any?(&:running?)
            sleep 1
          end

          managers.each do |manager|
            SqsWorker.logger.info(event_name: 'sqs_worker_shutdown_complete', type: manager.worker_class)
          end

          managers.each(&:terminate)

        end
      end

    rescue Interrupt
      exit 0
    end

    def self.on_signal_received(read_io, &block)
      IO.select([read_io]) #This will block until signal received
      yield
    end

    def self.trap_signals(write_io)
      %w(SIGTERM TERM SIGINT).each do |signal|
        Signal.trap(signal) do
          write_io.puts(signal)
        end
      end
    end

  end

end
