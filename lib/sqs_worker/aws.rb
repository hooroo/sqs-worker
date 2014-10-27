require 'aws-sdk'
require 'singleton'

module SqsWorker
  class Aws

    include Singleton

    def find_queue(queue_name)
      sqs.queues.named(queue_name.to_s)
    end

    private

    def sqs
      @sqs ||= ::AWS::SQS.new(SqsWorker.configuration)
    end

  end
end
