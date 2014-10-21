require 'sqs_worker/manager'

module SqsWorker

  class Runner

    # Subscribes actors to receive system signals
    # Each actor when receives a signal should execute
    # appropriate code to exit cleanly
    def self.run_all

      self_read, self_write = IO.pipe

      ['SIGTERM', 'TERM', 'SIGINT'].each do |sig|
        begin
          trap sig do
            self_write.puts(sig)
          end
        rescue ArgumentError
          puts "Signal #{sig} not supported"
        end
      end

      begin

        managers.each(&:bootstrap)

        while readable_io = IO.select([self_read])

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

    def self.managers
      @managers ||= worker_classes.map { |worker_class| Manager.new(worker_class) }
    end


    def self.worker_classes

      worker_file_names.inject([]) do |workers, file_name|

        worker_class = file_name.gsub('.rb','').camelize.constantize

        if worker_class.ancestors.include?(SqsWorker::Worker)
          workers << worker_class
        end

        workers
      end
    end

    def self.worker_file_names
      Dir.entries(Rails.root.join('app', 'workers')).select { |file_name| file_name.end_with?('worker.rb') }.reverse
    end

  end

end