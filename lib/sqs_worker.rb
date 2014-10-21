require 'celluloid'
require "sqs_worker/version"
require "sqs_worker/runner"
require 'sqs_worker/worker'

module SqsWorker

  def self.run_all
    require 'celluloid/autostart'
    Runner.run_all
  end

  def self.configure
    yield self
  end

  def self.configuration
    @configuration
  end

  def self.configuration=(value)
    @configuration = value
  end
end
