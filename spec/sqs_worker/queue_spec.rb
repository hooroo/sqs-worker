require 'spec_helper'
require 'sqs_worker/queue'

module SqsWorker
  describe Queue do

    subject { described_class.new(client, queue_url, queue_name, message_factory: message_factory) }

    let(:queue_name) { 'q-tastic' }
    let(:client) { instance_double(Aws::SQS::Client, send_message: nil) }
    let(:queue_url) { 'queue_url' }
    let(:message_factory) { instance_double(MessageFactory, message: constructed_message) }
    let(:message_to_publish) { { test: "message" } }
    let(:constructed_message) { { another: "message" } }
    let(:logger) { double('logger', info: nil) }

    before do
      allow(SqsWorker).to receive(:logger).and_return(logger)
      subject.send_message(message_to_publish)
    end

    describe "#send_message" do

      it "uses the message factory to construct a message with the given message body JSON and queue url" do
        expect(message_factory).to have_received(:message).with(
          message_body: message_to_publish.to_json,
          queue_url: queue_url
        )
      end

      it "sends the constructed message via the sqs client" do
        expect(client).to have_received(:send_message).with(constructed_message)
      end

      it "logs the event being sent" do
        expect(logger).to have_received(:info).with(event_name: 'sqs_worker_sent_message', queue_name: queue_name)
      end
    end
  end
end