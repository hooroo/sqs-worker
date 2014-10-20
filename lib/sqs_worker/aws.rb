require 'aws-sdk'

module SqsWorker
  module AWS

    def init_queue(queue_name, configuration = {})
      sqs = ::AWS::SQS.new(configuration)
      self.queue = sqs.queues.named(queue_name.to_s)
    end

    def fetch_sqs_messages
      queue.receive_message(:limit => 10, :attributes => [:receive_count])
    end

    def delete_sqs_messages(messages)
      queue.batch_delete(messages)
    end

    private

    attr_accessor :queue

  end
end
