require 'json'
require 'sqs_worker/errors'

module SqsWorker
  class MessageParser

    def parse(message)
      parsed_message = JSON.parse(message.body).deep_symbolize_keys
      parsed_message = JSON.parse(parsed_message[:Message]).deep_symbolize_keys if parsed_message[:Message]

      validate!(parsed_message)

      OpenStruct.new(body: parsed_message[:body], message_attributes: parsed_message[:message_attributes])

    rescue JSON::ParserError
      raise Errors::MessageFormat, 'Invalid JSON'
    end

    private

    def validate!(parsed_message)
      raise Errors::MessageFormat, 'Missing body' if parsed_message[:body].nil?
      raise Errors::MessageFormat, 'Missing message attributes' if parsed_message[:message_attributes].nil?
    end

  end
end
