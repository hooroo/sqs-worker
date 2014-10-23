require 'sqs_worker/manager'

module SqsWorker

  class Runner

    #Find all workers and start processing messages from their configured queues
    def self.run_all

      read_io, write_io = IO.pipe

      trap_signals(write_io)

      begin

        worker_classes = WorkerResolver.new.resolve_worker_classes
        managers = worker_classes.map { |worker_class| Manager.new(worker_class) }

        managers.each(&:bootstrap)

        while readable_io = IO.select([read_io])

          signal = readable_io.first[0].gets.strip

          managers.each(&:prepare_for_shutdown)

          while managers.all?(&:running?)
            sleep 2
          end

          managers.each(&:terminate)

          break
        end
      end

    rescue Interrupt
      exit 0
    end

    def self.trap_signals(write_io)
      ['SIGTERM', 'TERM', 'SIGINT'].each do |signal|
        trap(signal) do
          write_io.puts(signal)
        end
      end
    end

  end

end