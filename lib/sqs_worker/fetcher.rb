require 'sqs_worker/aws'

module SqsWorker
  class Fetcher
    include Celluloid

    MESSAGE_FETCH_LIMIT = 10
    RECEIVE_ATTRS = { :limit => MESSAGE_FETCH_LIMIT, :attributes => [:receive_count] }


    def initialize(queue_name:, manager:)
      @queue_name = queue_name
      @queue = Aws.instance.find_queue(queue_name)
      @manager = manager
    end

    def fetch
      messages = queue.receive_message(RECEIVE_ATTRS)
      log_fetched_messages(messages)
      manager.fetch_done(messages)
    end

    private

    attr_reader :manager, :queue, :queue_name

    def log_fetched_messages(messages)
      SqsWorker.logger.info(event_name: "sqs_worker_fetched_messages", queue: queue_name, size: messages.size) unless messages.empty?
    end

  end
end
