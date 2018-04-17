require 'spec_helper'
require 'sqs_worker/queue'

module SqsWorker
  describe Queue do

    subject { described_class.new(queue, queue_name, message_factory: message_factory) }

    let(:queue) { instance_double(Aws::SQS::Queue, send_message: nil, send_messages: nil) }
    let(:queue_name) { 'queue_name' }
    let(:message_factory) { instance_double(MessageFactory, message: message) }
    let(:message) { { message_attributes: { correlation_id: correlation_id } } }
    let(:correlation_id) { SecureRandom.uuid }

    let(:constructed_message) { { message_body: message.to_json, message_attributes: { correlation_id: { data_type: 'String', string_value: correlation_id } } } }
    let(:message_to_publish) { { test: 'message' } }
    let(:logger) { double('logger', info: nil) }

    before do
      allow(SqsWorker).to receive(:logger).and_return(logger)
    end

    describe '#send_message' do

      before { subject.send_message(message_to_publish) }

      it 'uses the message factory to construct a message' do
        expect(message_factory).to have_received(:message).with(message_to_publish)
      end

      it 'sends the constructed message' do
        expect(queue).to have_received(:send_message).with(constructed_message)
      end

      it 'logs the event being sent' do
        expect(logger).to have_received(:info).with(event_name: 'sqs_worker_sent_message', queue_name: queue_name)
      end
    end

    describe '#send_messages' do

      let(:message_to_publish) { [{ test: 'message' }] }
      let(:generated_id) { SecureRandom.uuid }

      before do
        allow(SecureRandom).to receive(:uuid).and_return(generated_id)
        subject.send_messages(message_to_publish)
      end

      it 'uses the message factory to construct a message' do
        message_to_publish.each do |msg|
          expect(message_factory).to have_received(:message).with(msg)
        end
      end

      it 'sends the constructed message' do
        expect(queue).to have_received(:send_messages).with(entries: [constructed_message.merge(id: generated_id)])
      end

      it 'logs the event being sent' do
        expect(logger).to have_received(:info).with(event_name: 'sqs_worker_batch_sent_message', queue_name: queue_name)
      end

      context 'when there are no messages to send' do

        let(:message_to_publish) { [] }

        it 'sends the constructed message' do
          expect(queue).not_to have_received(:send_messages)
        end
      end
    end
  end
end
