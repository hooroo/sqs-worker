class MessageFactory

  # Simulate the SQS message body / attribtues that will be available in v2 of the sdk
  def message(body)
    {
      message_attributes: {     # need to change to this: https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SNS/Types/MessageAttributeValue.html
        'correlation_id' => {
          data_type: 'String',
          string_value: correlation_id
        }
      },
      message: parse_message(body) # needs to change message to message and must be a _string_ not a JSON. Not sure if this matters or not if you don't change the `message_structure` attribute
    }
  end


  private

  attr_reader :body

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