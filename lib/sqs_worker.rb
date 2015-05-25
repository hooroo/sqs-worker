require 'celluloid'
require 'sqs_worker/version'
require 'sqs_worker/runner'
require 'sqs_worker/worker'
require 'sqs_worker/configuration'

module SqsWorker

  def self.run_all
    require 'celluloid/autostart'
    Runner.run_all
  end

  def self.logger
    raise "Please specify a logger for the sqs worker gem via SqsWorker.logger = my_logger" if @logger.nil?
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.configure
    yield(config)
  end

  def self.config
    @config ||= Configuration.new
  end

end
