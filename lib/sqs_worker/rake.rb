require 'sqs_worker'

namespace :sqs_worker do

  task :run_all => :environment do

    def setup_sqs_without_debug_logging
      Aws.config.update({ log_level: :debug })
      sqs = Aws::SQS.Resource.new
      sqs.config.logger.level = 1
      sqs
    end

    loop do
      begin
        sqs = setup_sqs_without_debug_logging

        break unless sqs.queues.first.nil?
      rescue Errno::ECONNREFUSED
        puts 'Waiting for the SQS Server to start...'
        sleep(0.5)
      end
    end

    puts 'Starting the SqsWorkers'
    STDOUT.flush
    SqsWorker.run_all
  end

end
