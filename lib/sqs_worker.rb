require "sqs_worker/version"
require "sqs_worker/runner"

module SqsWorker

  def self.run_all
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
