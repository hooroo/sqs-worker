require 'spec_helper'
require 'sqs_worker/fetcher'

module SqsWorker
  describe Fetcher do

    subject(:fetcher) { described_class.new(queue_name: queue_name, manager: manager) }

    let(:queue_name) { 'queue_name' }
    let(:manager) { double(Manager)}
    let (:aws) { double(Aws, find_queue: queue) }
    let (:queue) { double('queue') }
    let(:messages) { ['message'] }
    let(:logger) { double('logger', info: nil) }

    before do
      SqsWorker.logger = logger
      expect(Aws).to receive(:instance).and_return(aws)
      expect(aws).to receive(:find_queue).and_return(queue)
    end

    after do
      SqsWorker.logger = nil
    end

    it 'fetches messages from the queue and passes to manager' do
      expect(queue).to receive(:receive_message).with(Fetcher::RECEIVE_ATTRS).and_return(messages)
      expect(manager).to receive(:fetch_done).with(messages)
      expect(logger).to receive(:info).with(event_name: "sqs_worker_fetched_messages", queue: queue_name, size: messages.size)
      fetcher.fetch
    end

  end
end