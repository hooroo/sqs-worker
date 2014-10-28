require 'spec_helper'
require 'sqs_worker/sqs'

module SqsWorker
  describe Sqs do

    subject(:sqs) { described_class.clone.instance }

    let(:aws_sqs) { double(AWS::SQS) }
    let(:queues) { double('queues') }
    let(:queue) { double('queue') }
    let(:queue_name) { 'test_queue' }

    describe '#find_queue' do

      it "finds the queue" do
        expect(AWS::SQS).to receive(:new).and_return(aws_sqs)
        expect(aws_sqs).to receive(:queues).and_return(queues)
        expect(queues).to receive(:named).with(queue_name).and_return(queue)
        expect(sqs.find_queue(queue_name)).to eq(queue)
      end
    end
  end
end