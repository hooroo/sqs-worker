require 'spec_helper'
require 'sqs_worker/deleter'

module SqsWorker
  describe Deleter do


    subject(:deleter) { described_class.new(queue_name)}
    let(:queue_name) { 'queue_name' }

    let (:sqs) { double(Sqs, find_queue: queue) }
    let (:queue) { double('queue') }

    before do
      expect(Sqs).to receive(:instance).and_return(sqs)
      expect(sqs).to receive(:find_queue).and_return(queue)
    end

    context 'with messages' do

      let(:messages) { ['message'] }

      it 'deletes message from the queue' do
        expect(queue).to receive(:batch_delete).with(messages)
        deleter.delete(messages)
      end
    end

    context 'without messages' do

      let(:messages) { [] }

      it 'deletes message from the queue' do
        expect(queue).to_not receive(:batch_delete).with(messages)
        deleter.delete(messages)
      end
    end


  end
end