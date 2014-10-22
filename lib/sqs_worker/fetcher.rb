require 'sqs_worker/aws'

module SqsWorker
  class Fetcher
    include Celluloid

    MESSAGE_FETCH_LIMIT = 10
    RECEIVE_ATTRS = { :limit => MESSAGE_FETCH_LIMIT, :attributes => [:receive_count] }


    def initialize(queue_name:, manager:)
      @queue = AWS.instance.find_queue(queue_name)
      @manager = manager
    end

    def fetch
      messages = queue.receive_message(RECEIVE_ATTRS)
      manager.fetch_done(messages)
    end

    private

    attr_reader :manager, :queue

  end
end
