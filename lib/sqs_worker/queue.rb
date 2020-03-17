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
      message_payload = build_message_payload_from(message_body)

      @queue.send_message(message_payload)
      SqsWorker.logger.debug(event_name: 'sqs_worker_sent_message', queue_name: name)
    end

    def send_messages(message_list)
      message_bodies = message_list.map { |message| message_factory.message(message) }

      entries = message_bodies.map do |message_body|
        build_message_payload_from(message_body).merge(id: SecureRandom.uuid)
      end

      if entries.any?
        @queue.send_messages(entries: entries)
        SqsWorker.logger.debug(event_name: 'sqs_worker_batch_sent_message', queue_name: name)
      end
    end

    private

    attr_reader :queue, :name, :message_factory

    def build_message_payload_from(message_body)
      {
        message_body: message_body.to_json,
        message_attributes: {
          correlation_id: {
            data_type: 'String',
            string_value: message_body[:message_attributes][:correlation_id]
          },
          event_type: {
            data_type: 'String',
            string_value: message_body[:message_attributes][:event_type]
          }
        }
      }
    end

  end
end
