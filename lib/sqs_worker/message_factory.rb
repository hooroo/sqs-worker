class MessageFactory

  # Simulate the SQS message body / attribtues that will be available in v2 of the sdk
  def message(body)
    {
      message_attributes: {
        correlation_id: correlation_id,
        event_type: event_type(body) || 'unknown'
      },
      body: parse_message(body)
    }
  end


  private

  attr_reader :body

  def correlation_id
    Thread.current[:correlation_id] ||= SecureRandom.uuid
  end

  def event_type(body)
    body.event_type if defined?(body.event_type)
  end

  def parse_message(message)
    if message.kind_of?(String)
      JSON.parse(message)
    else
      message
    end
  end

end
