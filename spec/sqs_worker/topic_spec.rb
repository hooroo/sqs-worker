require 'spec_helper'
require 'sqs_worker/topic'

module SqsWorker
  describe Topic do

    subject(:wrapped_topic) { described_class.new(topic, message_factory: message_factory) }

    let(:topic) do
      instance_double(Aws::SNS::Topic, publish: nil, attributes: { 'DisplayName' => topic_name})
    end
    let(:topic_name) { 'topic_name' }
    let(:message_factory) { instance_double(MessageFactory, message: constructed_message) }
    let(:message_to_publish) { { test: "message" } }
    let(:constructed_message) { { another: "message" } }
    let(:logger) { double('logger', info: nil) }

    before do
      allow(SqsWorker).to receive(:logger).and_return(logger)
      subject.send_message(message_to_publish)
    end

    describe "#send_message" do

      it "uses the message factory to construct a message from the given message JSON" do
        expect(message_factory).to have_received(:message).with(
          message: message_to_publish.to_json
        )
      end

      it "sends the constructed message" do
        expect(topic).to have_received(:publish).with(constructed_message)
      end

      it "logs the event being sent along with the topic display name" do
        expect(logger).to have_received(:info).with(event_name: 'sqs_worker_sent_message', topic_name: topic_name)
      end
    end

    describe '#name' do
      it 'is the topic display name' do
        expect(wrapped_topic.name).to eq(topic_name)
      end
    end
  end
end