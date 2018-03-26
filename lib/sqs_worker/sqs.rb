require 'aws-sdk-v1'
require 'singleton'
require 'sqs_worker/queue'
require 'sqs_worker/errors'

module SqsWorker
  class Sqs < SimpleDelegator

    include Singleton

    def initialize
      Aws.config.update({ log_level: :debug })
      @sqs = ::Aws::SQS.Resource.new(logger: SqsWorker.logger)
      @queues = sqs.queues
      @queue_cache = {}
      super(@sqs)
    end

    def find_queue(queue_name)
      @queue_cache[queue_name] ||= Queue.new(queues.named(queue_name.to_s), queue_name.to_s)
    rescue Aws::SQS::Errors::NonExistentQueue => e
      raise SqsWorker::Errors::NonExistentQueue, "No queue found with name '#{queue_name}'"
    end

    private

    attr_reader :sqs, :queues, :queue_cache

  end

end
