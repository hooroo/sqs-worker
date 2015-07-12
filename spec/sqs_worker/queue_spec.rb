require 'spec_helper'
require 'sqs_worker/queue'

module SqsWorker
  describe Queue do

    subject { described_class.new(queue, queue_name, message_factory: message_factory) }

    let(:queue) { instance_double(AWS::SQS::Queue, send_message: nil) }
    let(:queue_name) { 'queue_name' }
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
        expect(queue).to have_received(:send_message).with(constructed_message.to_json)
      end

      it 'logs the event being sent' do
        expect(logger).to have_received(:info).with(event_name: 'sqs_worker_sent_message', queue_name: queue_name)
      end
    end
  end
end
