require 'spec_helper'
require 'aws-sdk-sns'
require 'sqs_worker/topic'

module SqsWorker
  describe Topic do

    subject { described_class.new(topic, message_factory: message_factory) }

    let(:topic) { instance_double(Aws::SNS::Topic, publish: nil, attributes: {'DisplayName' => topic_name}) }
    let(:topic_name) { 'topic_name' }
    let(:message_factory) { instance_double(MessageFactory, message: constructed_message) }
    let(:message_to_publish) { { test: 'message' } }
    let(:constructed_message) { { another: 'message' } }
    let(:logger) { double('logger', info: nil) }

    before do
      allow(SqsWorker).to receive(:logger).and_return(logger)
      subject.send_message(message_to_publish)
    end

    describe '#send_message' do

      it 'uses the message factory to construct a message' do
        expect(message_factory).to have_received(:message).with(message_to_publish)
      end

      it 'sends the constructed message' do
        expect(topic).to have_received(:publish).with(constructed_message.to_json)
      end

      it 'logs the event being sent' do
        expect(logger).to have_received(:info).with(event_name: 'sqs_worker_sent_message', topic_name: topic_name)
      end
    end
  end
end
