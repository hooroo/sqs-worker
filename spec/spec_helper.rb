require 'celluloid/test'
require 'sqs_worker'
require 'sqs_worker/support/logger_setup'
require 'byebug'
require 'timecop'

RSpec.configure do |config|

  config.order = 'random'

  config.include LoggerSetup

  config.before(:each) do
    Celluloid.boot
    SqsWorker.config.worker_configurations.clear
    SqsWorker.logger = logger
    SqsWorker.heartbeat_logger = logger
  end

  config.after(:each) do
    Celluloid.shutdown
    Timecop.return
    SqsWorker.logger = nil
    SqsWorker.heartbeat_logger = nil
  end
end
