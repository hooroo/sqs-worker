require 'delegate'
require_relative 'message_factory'

module SqsWorker
  class Topic < SimpleDelegator

    def initialize(topic, message_factory: MessageFactory.new)
      super(topic)
      @topic = topic
      @message_factory = message_factory
    end

    def send_message(message_body)
      message_body = message_factory.message(message_body)
      message_payload = build_message_payload_from(message_body)

      @topic.publish(message_payload)
      SqsWorker.logger.debug(event_name: 'sqs_worker_sent_message', topic_name: topic.attributes['DisplayName'])
    end


    private

    attr_reader :topic, :message_factory

    def build_message_payload_from(message_body)
      {
        message: message_body.to_json,
        message_attributes: {
          correlation_id: {
            data_type: 'String',
            string_value: message_body[:message_attributes][:correlation_id]
          }
        }
      }
    end

  end
end
