require 'spec_helper'
require 'sqs_worker/fetcher'

module SqsWorker
  describe Fetcher do

    subject(:fetcher) { described_class.new(queue_name: queue_name, manager: manager) }

    let(:queue_name) { 'queue_name' }
    let(:manager) { double(Manager)}
    let (:aws) { double(AWS, find_queue: queue) }
    let (:queue) { double('queue') }
    let(:messages) { ['message'] }

    before do
      expect(AWS).to receive(:instance).and_return(aws)
      expect(aws).to receive(:find_queue).and_return(queue)
    end

    it 'fetches messages from the queue and passes to manager' do
      expect(queue).to receive(:receive_message).with(Fetcher::RECEIVE_ATTRS).and_return(messages)
      expect(manager).to receive(:fetch_done).with(messages)
      fetcher.fetch
    end

  end
end