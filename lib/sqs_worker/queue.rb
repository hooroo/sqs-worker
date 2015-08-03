require 'delegate'
require_relative 'message_factory'

module SqsWorker
  class Queue < SimpleDelegator

    def initialize(queue, name, message_factory: MessageFactory.new)
      super(queue)
      @queue = queue
      @name = name
      @message_factory = message_factory
    end

    def send_message(message_body)
      @queue.send_message(message_factory.message(message_body).to_json)
      SqsWorker.logger.info(event_name: 'sqs_worker_sent_message', queue_name: name)
    end


    private

    attr_reader :queue, :name, :message_factory

  end
end