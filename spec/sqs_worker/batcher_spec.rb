require 'spec_helper'
require 'sqs_worker/batcher'

module SqsWorker
  describe Batcher do

    subject(:batcher) { described_class.new(manager: manager, processor: processor_pool) }

    let(:manager) { double(Manager) }
    let(:processor) { double(Processor) }
    let(:processor_pool) { double('processor_pool', future: processor) }
    let(:messages) { [successful_message, unsuccessful_message] }
    let(:successful_message) { 'successful' }
    let(:successful_message_future) { double('successful_message_future', value: successful_result) }
    let(:unsuccessful_message) { 'unsuccessful' }
    let(:unsuccessful_message_future) { double('unsuccessful_message_future', value: unsuccessful_result) }
    let(:successful_result) { { success: true, message: successful_message } }
    let(:unsuccessful_result) { { success: false, message: unsuccessful_message } }


    describe '#process' do
      context 'when not shutting down' do

        it 'processes messages and calls batch_done with successfully processed messages' do

          expect(processor).to receive(:process).with(successful_message).and_return(successful_message_future)
          expect(processor).to receive(:process).with(unsuccessful_message).and_return(unsuccessful_message_future)
          expect(manager).to receive(:batch_done).with([successful_message])
          batcher.process(messages)

        end

      end

      context 'when shutting down' do

        before do
          batcher.publish('SIGTERM')
        end

        it 'does not process the message and calls manager batch_done with empty array' do
          expect(processor).to_not receive(:process)
          expect(manager).to receive(:batch_done).with([])
          batcher.process(messages)
        end
      end

    end

    it 'subscribes for shutdown' do
      batcher.publish('SIGTERM')
      expect(batcher.shutting_down?).to be true
    end

  end
end
