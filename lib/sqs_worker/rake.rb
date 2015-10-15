require 'sqs_worker'

namespace :sqs_worker do

  task :run_all => :environment do
    loop do
      begin
        break unless AWS::SQS.new.queues.first.nil?
      rescue Errno::ECONNREFUSED
        puts 'Waiting for the SQS Server to start...'
        sleep(0.5)
      end
    end
    puts 'Starting the SqsWorkers'
    SqsWorker.run_all
  end

end
