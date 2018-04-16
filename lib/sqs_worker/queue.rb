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
      message_body = message_factory.message(message_body)

      message_payload = {
          message_attributes: {
            'correlation_id' => {
              data_type: 'String',
              string_value: message_body[:message_attributes][:correlation_id]
            }
          },
          message_body: message_body.to_json
      }
      @queue.send_message(message_payload) ## This needs to be a hash
      SqsWorker.logger.info(event_name: 'sqs_worker_sent_message', queue_name: name)
    end

    def send_messages(message_list)
      message_body = message_list.map { |message| message_factory.message(message).to_json }
      @queue.send_messages(message_body)
      SqsWorker.logger.info(event_name: 'sqs_worker_batch_sent_message', queue_name: name)
    end

    private

    attr_reader :queue, :name, :message_factory

  end
end