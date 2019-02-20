require 'spec_helper'
require 'aws-sdk-sns'
require 'sqs_worker/topic'

module SqsWorker
  describe Topic do

    subject { described_class.new(topic, topic_name, message_factory: message_factory) }

    let(:topic) { instance_double(Aws::SNS::Topic, publish: nil) }
    let(:topic_name) { 'topic_name' }
    let(:message_factory) { instance_double(MessageFactory, message: message) }
    let(:message) { { message_attributes: { correlation_id: correlation_id } } }
    let(:correlation_id) { SecureRandom.uuid }

    let(:constructed_message) { { message: message.to_json, message_attributes: { correlation_id: { data_type: 'String', string_value: correlation_id } } } }
    let(:message_to_publish) { { test: 'message' } }

    before do
      subject.send_message(message_to_publish)
    end

    describe '#send_message' do

      it 'uses the message factory to construct a message' do
        expect(message_factory).to have_received(:message).with(message_to_publish)
      end

      it 'sends the constructed message' do
        expect(topic).to have_received(:publish).with(constructed_message)
      end

      it 'logs the event being sent' do
        expect(logger).to have_received(:debug).with(event_name: 'sqs_worker_sent_message', topic_name: topic_name)
      end
    end

  end
end
