class MessageFactory

  # Simulate the SQS message body / attribtues that will be available in v2 of the sdk
  def message(message_details)
    message_details.merge(
      message_attributes: {
        correlation_id: correlation_id
      }
    )
  end


  private

  attr_reader :body

  def correlation_id
    Thread.current[:correlation_id] ||= SecureRandom.uuid
  end

end