class MessageFactory

  # Simulate the SQS message body / attribtues that will be available in v2 of the sdk
  def message(body)
    {
      message_attributes: {
        correlation_id: correlation_id
      },
      body: parse_message(body)
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