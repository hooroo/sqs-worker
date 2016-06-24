require 'webmock'
require 'cgi'

class FakeSqs
  include WebMock::API
  include WebMock::Matchers

  def initialize()
    @times_to_fail = Hash.new { |h, k| h[k] = 0 }
    @mutex = Mutex.new

    @delete_call_count = 0

    start_fake_service
  end

  def will_fail_to_fetch_messages(times)
    @times_to_fail[:message] = times
  end

  def will_fail_to_fetch_queue_details(times)
    @times_to_fail[:queue_url] = times
  end

  def will_fail_to_delete_messages(times)
    @times_to_fail[:delete] = times
  end


  attr_reader :delete_call_count
  attr_accessor :times_to_fail

  private


  attr_reader :mutex

  def check_if_still_failing(type)
    mutex.synchronize do
      @times_to_fail[type] -= 1 unless @times_to_fail[type] < 1
    end

    times_to_fail[type] > 0
  end

  def start_fake_service
    stub_request(:any, /http:\/\/localhost:4568.*/).to_return do |request|
      params = parse_params(request.body)

      action = params['Action'] || []

      if action.include?('GetQueueUrl')
        service_get_queue_url(params['QueueName'])
      elsif action.include?('ReceiveMessage')
        service_receive_message
      elsif action.include?('DeleteMessageBatch')
        service_delete_messages
      else
        { status: 500, headers: {}, body: '' }
      end

    end
  end

  def service_receive_message
    if check_if_still_failing(:message)
      { status: 500, headers: {}, body: '' }
    else
      { status: 200, headers: {}, body: successful_receive_message_body('{ "body" : {}, "message_attributes" : {} }') }
    end
  end

  def service_delete_messages
    if check_if_still_failing(:delete)
      { status: 500, headers: {}, body: '' }
    else
      mutex.synchronize do
        @delete_call_count += 1
      end

      { status: 200, headers: {}, body: delete_payload }
    end
  end

  def delete_payload
    <<-PAYLOAD
<DeleteMessageBatchResponse>
    <DeleteMessageBatchResult>
        <DeleteMessageBatchResultEntry>
            <Id>msg1</Id>
        </DeleteMessageBatchResultEntry>
        <DeleteMessageBatchResultEntry>
            <Id>msg2</Id>
        </DeleteMessageBatchResultEntry>
    </DeleteMessageBatchResult>
    <ResponseMetadata>
        <RequestId>d6f86b7a-74d1-4439-b43f-196a1e29cd85</RequestId>
    </ResponseMetadata>
</DeleteMessageBatchResponse>
    PAYLOAD
  end

  def successful_receive_message_body(body_json)
    md5 = Digest::MD5.hexdigest(body_json)
    <<-PAYLOAD
    <ReceiveMessageResponse>
  <ReceiveMessageResult>
    <Message>
      <MessageId>
        5fea7756-0ea4-451a-a703-a558b933e274
      </MessageId>
      <ReceiptHandle>
        MbZj6wDWli+JvwwJaBV+3dcjk2YW2vA3+STFFljTM8tJJg6HRG6PYSasuWXPJB+Cw
        Lj1FjgXUv1uSj1gUPAWV66FU/WeR4mq2OKpEGYWbnLmpRCJVAyeMjeU5ZBdtcQ+QE
        auMZc8ZRv37sIW2iJKq3M9MFx1YvV11A2x/KSbkJ0=
      </ReceiptHandle>
      <MD5OfBody>#{md5}</MD5OfBody>
      <Body>#{body_json}</Body>
      <Attribute>
        <Name>SenderId</Name>
        <Value>195004372649</Value>
      </Attribute>
      <Attribute>
        <Name>SentTimestamp</Name>
        <Value>1238099229000</Value>
      </Attribute>
      <Attribute>
        <Name>ApproximateReceiveCount</Name>
        <Value>5</Value>
      </Attribute>
      <Attribute>
        <Name>ApproximateFirstReceiveTimestamp</Name>
        <Value>1250700979248</Value>
      </Attribute>
    </Message>
  </ReceiveMessageResult>
  <ResponseMetadata>
    <RequestId>
      b6633655-283d-45b4-aee4-4e84e0ae6afa
    </RequestId>
  </ResponseMetadata>
</ReceiveMessageResponse>
    PAYLOAD
  end

  def service_get_queue_url(queue_name_params)
    unless check_if_still_failing(:queue_url)
      queue_name_params ||= []

      queue_name = queue_name_params.first

      body = <<-PAYLOAD
  <GetQueueUrlResponse>
      <GetQueueUrlResult>
          <QueueUrl>http://localhost:4568/123456789012/#{queue_name}</QueueUrl>
      </GetQueueUrlResult>
      <ResponseMetadata>
          <RequestId>470a6f13-2ed9-4181-ad8a-2fdea142988e</RequestId>
      </ResponseMetadata>
  </GetQueueUrlResponse>
      PAYLOAD

      { status: 200, headers: {}, body: body }
    else
      { status: 500, headers: {}, body: '' }
    end

  end

  def parse_params(payload)
    CGI.parse(payload)
  end
end