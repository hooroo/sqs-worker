require 'spec_helper'
require 'sqs_worker/deleter'

module SqsWorker
  describe Deleter do

    subject(:deleter) { described_class.new(queue_name) }

    let(:queue_name) { 'queue_name' }

    let(:sqs) { double(Sqs, find_queue: queue) }
    let(:queue) { double('queue') }

    before do
      expect(Sqs).to receive(:instance).and_return(sqs)
      expect(sqs).to receive(:find_queue).and_return(queue)
    end

    context 'with messages' do

      let(:messages) { [first_message, second_message] }
      let(:first_message) { OpenStruct.new(message_id: SecureRandom.uuid, receipt_handle: SecureRandom.uuid) }
      let(:second_message) { OpenStruct.new(message_id: SecureRandom.uuid, receipt_handle: SecureRandom.uuid) }

      let(:entries) do
        [
          {
            id: first_message.message_id,
            receipt_handle: first_message.receipt_handle
          },
          {
            id: second_message.message_id,
            receipt_handle: second_message.receipt_handle
          }
        ]
      end

      it 'deletes message from the queue' do
        expect(queue).to receive(:delete_messages).with(entries: entries)
        deleter.delete(messages)
      end
    end

    context 'without messages' do

      let(:messages) { [] }

      it 'deletes message from the queue' do
        expect(queue).to_not receive(:delete_messages)
        deleter.delete(messages)
      end
    end

  end
end