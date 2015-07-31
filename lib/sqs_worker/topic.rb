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
      @topic.publish(message_factory.message(message: message_body.to_json))
      SqsWorker.logger.info(event_name: 'sqs_worker_sent_message', topic_name: name)
    end

    def name
      topic.attributes['DisplayName']
    end

    private

    attr_reader :topic, :message_factory

  end
end
