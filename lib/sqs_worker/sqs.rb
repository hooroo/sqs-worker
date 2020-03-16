require 'aws-sdk-sqs'
require 'singleton'
require 'sqs_worker/queue'
require 'sqs_worker/errors'

module SqsWorker
  class Sqs < SimpleDelegator

    include Singleton

    def initialize
      Aws.config.update({ log_level: :error })
      # debug log level was logging sqs messages which caused PI leakage for flightbooking events
      @sqs = ::Aws::SQS::Resource.new(logger: SqsWorker.logger)
      @queue_cache = {}
      super(@sqs)
    end

    def find_queue(queue_name)
      queue = sqs.get_queue_by_name({queue_name: queue_name.to_s})
      @queue_cache[queue_name] ||= Queue.new(queue, queue_name.to_s)
    rescue Aws::SQS::Errors::NonExistentQueue => e
      puts e
      raise SqsWorker::Errors::NonExistentQueue, "No queue found with name '#{queue_name}'"
    end

    private

    attr_reader :sqs, :queues, :queue_cache

  end

end
