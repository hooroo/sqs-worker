require 'sqs_worker/sqs'

module SqsWorker
  class Fetcher
    include Celluloid

    def initialize(queue_name:, manager:, batch_size:)
      @queue_name = queue_name
      @queue = Sqs.instance.find_queue(queue_name)
      @manager = manager
      @batch_size = batch_size
    end

    def fetch
      puts "fetching messages: #{batch_size}"
      x = queue.receive_messages({ max_number_of_messages: batch_size, attribute_names: ['ApproximateReceiveCount'] })
      puts "result: #{x}"
      messages = Array(x)
      puts "Fetch Messages: #{messages}"
      log_fetched_messages(messages)
      manager.fetch_done(messages)
    rescue => e
      SqsWorker.logger.error(error: e)
      puts e
      manager.fetch_done([])
    end

    private

    attr_reader :manager, :queue, :queue_name, :batch_size

    def log_fetched_messages(messages)
      SqsWorker.logger.info(event_name: 'sqs_worker_fetched_messages', queue_name: queue_name, size: messages.size) unless messages.empty?
    end

  end
end
