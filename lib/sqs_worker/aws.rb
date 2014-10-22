require 'aws-sdk'
require 'singleton'

module SqsWorker
  class AWS

    include Singleton

    def initialize
      @sqs = ::AWS::SQS.new(SqsWorker.configuration)
    end

    def find_queue(queue_name)
      sqs.queues.named(queue_name.to_s)
    end

    private

    attr_reader :sqs

  end
end
