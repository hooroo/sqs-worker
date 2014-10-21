require 'sqs_worker/aws'

module SqsWorker
  class Deleter
    include Celluloid
    include SqsWorker::AWS

    def initialize(queue_name:, configuration: {})
      init_queue(queue_name, configuration)
    end

    def delete(messages)
      delete_sqs_messages(messages) if not messages.empty?
    end
  end
end
