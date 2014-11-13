require 'aws-sdk'
require 'singleton'
require 'sqs_worker/queue'

module SqsWorker
  class Sqs < SimpleDelegator

    include Singleton

    def initialize
      @sqs = ::AWS::SQS.new
      super(@sqs)
    end

    def find_queue(queue_name)
      Queue.new(sqs.queues.named(queue_name.to_s), queue_name.to_s)
    end

    private

    attr_reader :sqs

  end

end


