require 'aws-sdk-v1'
require 'singleton'
require 'sqs_worker/queue'
require 'sqs_worker/errors'

module SqsWorker
  class Sqs < SimpleDelegator

    include Singleton

    def initialize
      @sqs = ::AWS::SQS.new
      super(@sqs)
    end

    def find_queue(queue_name)
      Queue.new(sqs.queues.named(queue_name.to_s), queue_name.to_s)
    rescue AWS::SQS::Errors::NonExistentQueue => e
      raise SqsWorker::Errors::NonExistentQueue, "No queue found with name '#{queue_name}'"
    end

    private

    attr_reader :sqs

  end

end
