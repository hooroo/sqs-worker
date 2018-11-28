require 'spec_helper'
require 'sqs_worker/fetcher'

module SqsWorker
  describe Fetcher do

    subject(:fetcher) { described_class.new(queue_name: queue_name, manager: manager, batch_size: batch_size) }

    let(:batch_size) { 5 }
    let(:queue_name) { 'queue_name' }
    let(:manager) { double(Manager, fetch_done: nil)}
    let(:sqs) { double(Sqs, find_queue: queue) }
    let(:queue) { double('queue') }
    let(:messages) { ['message'] }

    before do
      expect(Sqs).to receive(:instance).and_return(sqs)
      expect(sqs).to receive(:find_queue).and_return(queue)
    end

    describe 'normal operation' do

      before do
        expect(queue).to receive(:receive_messages).with({ max_number_of_messages: batch_size, attribute_names: ['ApproximateReceiveCount'] }).and_return(messages)
        fetcher.fetch
      end

      it 'fetches messages from the queue and passes to manager' do
        expect(manager).to have_received(:fetch_done).with(messages)
      end

      it 'logs the successful fetching of messages' do
        expect(logger).to have_received(:debug).with(event_name: 'sqs_worker_fetched_messages', queue_name: queue_name, size: messages.size)
      end

      context 'when there is a single message returned (ie batch size is 1)' do
        let(:messages) { 'message' }

        it 'fetches messages from the queue and passes to manager, as an array' do
          expect(manager).to have_received(:fetch_done).with([messages])
        end

        it 'logs the successful fetching of messages' do
          expect(logger).to have_received(:debug).with(event_name: 'sqs_worker_fetched_messages', queue_name: queue_name, size: 1)
        end
      end
    end

    describe 'when there are errors in the client' do

      let(:exception) { 'errors ahoy!' }

      before do
        expect(queue).to receive(:receive_messages).with(anything).and_raise(exception)
        fetcher.fetch
      end

      it 'messages the manager with empty messages' do
        expect(manager).to have_received(:fetch_done).with([])
      end

      it 'logs the error' do
        expect(logger).to have_received(:error).with(error: an_instance_of(RuntimeError))
      end
    end
  end
end
