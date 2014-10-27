require 'spec_helper'
require 'sqs_worker/aws'

module SqsWorker
  describe Aws do

    subject(:aws) { described_class.clone.instance }

    let(:sqs) { double(AWS::SQS) }
    let(:queues) { double('queues') }
    let(:queue) { double('queue') }
    let(:queue_name) { 'test_queue' }

    describe '#find_queue' do

      it "finds the queue" do
        expect(AWS::SQS).to receive(:new).with(SqsWorker.configuration).and_return(sqs)
        expect(sqs).to receive(:queues).and_return(queues)
        expect(queues).to receive(:named).with(queue_name).and_return(queue)
        expect(aws.find_queue(queue_name)).to eq(queue)
      end
    end
  end
end