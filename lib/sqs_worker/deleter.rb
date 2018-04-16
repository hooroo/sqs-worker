require 'sqs_worker/sqs'

module SqsWorker
  class Deleter
    include Celluloid

    def initialize(queue_name)
      @queue = Sqs.instance.find_queue(queue_name)
    end

    def delete(messages)
      entries = messages.map do |m|
        {
          id: m.message_id,
          receipt_handle: m.receipt_handle
        }
      end
      queue.delete_messages({entries: entries}) unless entries.empty?
    end

    private

    attr_reader :queue

  end
end
