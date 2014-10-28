require 'sqs_worker/sqs'

module SqsWorker
  class Deleter
    include Celluloid

    def initialize(queue_name)
      @queue = Sqs.instance.find_queue(queue_name)
    end

    def delete(messages)
      queue.batch_delete(messages) unless messages.empty?
    end

    private

    attr_reader :queue

  end
end
