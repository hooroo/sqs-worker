require 'spec_helper'
require 'sqs_worker/fetcher'

module SqsWorker
  describe Fetcher do

    subject(:fetcher) { described_class.new(queue_name: queue_name, manager: manager, batch_size: batch_size) }

    let(:batch_size) { 5 }
    let(:queue_name) { 'queue_name' }
    let(:manager) { double(Manager, fetch_done: nil)}
    let (:sqs) { double(Sqs, find_queue: queue) }
    let (:queue) { double('queue') }
    let(:messages) { ['message'] }
    let(:logger) { double('logger', info: nil, error: nil) }

    before do
      SqsWorker.logger = logger
      expect(Sqs).to receive(:instance).and_return(sqs)
      expect(sqs).to receive(:find_queue).and_return(queue)
    end

    after do
      SqsWorker.logger = nil
    end

    describe 'normal operation' do
      before do
        expect(queue).to receive(:receive_message).with({ :limit => batch_size, :attributes => [:receive_count] }).and_return(messages)

        fetcher.fetch
      end

      it 'fetches messages from the queue and passes to manager' do
        expect(manager).to have_received(:fetch_done).with(messages)
      end

      it 'logs the successful fetching of messages' do
        expect(logger).to have_received(:info).with(event_name: 'sqs_worker_fetched_messages', queue_name: queue_name, size: messages.size)
      end

      context 'when there is a single message returned (ie batch size is 1)' do
        let(:messages) { 'message' }

        it 'fetches messages from the queue and passes to manager, as an array' do
          expect(manager).to have_received(:fetch_done).with([messages])
        end

        it 'logs the successful fetching of messages' do
          expect(logger).to have_received(:info).with(event_name: 'sqs_worker_fetched_messages', queue_name: queue_name, size: 1)
        end
      end
    end

    describe 'when there are errors in the client' do
      let(:exception) { 'bad shit' }
      before do
        expect(queue).to receive(:receive_message).with(anything).and_raise('bad shit')

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
