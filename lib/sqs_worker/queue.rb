require 'delegate'

module SqsWorker
  class Queue < SimpleDelegator

    def initialize(queue, name)
      super(queue)
      @queue = queue
      @name = name
    end

    def send_message(message)
      @queue.send_message(with_message_attributes(message))
      Slate::Logger.info(event_name: 'sqs_worker_sent_message', queue_name: name)
    end


    private

    attr_reader :queue, :name

    #Simulate the SQS message body / attribtues that will be available in v2 of the sdk
    def with_message_attributes(message)
      {
        message_attributes: {
          correlation_id: correlation_id
        },
        body: parse_message(message)
      }.as_json.to_json
    end

    def correlation_id
      Thread.current[:correlation_id] ||= SecureRandom.uuid
    end

    def parse_message(message)
      if message.kind_of?(String)
        JSON.parse(message)
      else
        message
      end
    end

  end
end