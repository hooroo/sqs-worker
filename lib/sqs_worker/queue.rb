require 'delegate'
require_relative 'message_factory'

module SqsWorker
  class Queue

    def initialize(client, queue_url, queue_name, message_factory: MessageFactory.new)
      @client = client
      @queue_url = queue_url
      @queue_name = queue_name
      @message_factory = message_factory
    end

    def send_message(message_body)
      client.send_message(message_factory.message(message_body: message_body.to_json, queue_url: queue_url))
      SqsWorker.logger.info(event_name: 'sqs_worker_sent_message', queue_name: queue_name)
    end


    private

    attr_reader :client, :queue_url, :queue_name, :message_factory

  end
end