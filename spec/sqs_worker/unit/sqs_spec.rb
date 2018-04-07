require 'spec_helper'
require 'sqs_worker/sqs'

module SqsWorker
  describe Sqs do

    subject(:sqs) { described_class.clone.instance }

    let(:aws_sqs) { double(Aws::SQS::Resource, get_queue_by_name: queue) }
    let(:logger) { double('logger') }
    let(:queue) { instance_double(Aws::SQS::Queue) }
    let(:wrapped_queue) { instance_double(Queue)}
    let(:queue_name) { 'test_queue' }

    describe '#find_queue' do

      before do
        allow(SqsWorker).to receive(:logger).and_return(logger)
        allow(Aws::SQS::Resource).to receive(:new).and_return(aws_sqs)
        allow(Queue).to receive(:new).and_return(wrapped_queue)
      end

      it 'finds the queue using the correct queue name' do
        sqs.find_queue(queue_name)
        expect(aws_sqs).to have_received(:get_queue_by_name).with({queue_name: queue_name})
      end

      it 'creates the queue with the sqs queue and correct queue name' do
        sqs.find_queue(queue_name)
        expect(Queue).to have_received(:new).with(queue, queue_name)
      end

      it 'returns a wrapped queue instance' do
        expect(sqs.find_queue(queue_name)).to be(wrapped_queue)
      end

      context "when the queue doesn't exist" do

        before do
          allow(Queue).to receive(:new).and_raise(Aws::SQS::Errors::NonExistentQueue.new("context", "error message"))
        end

        it 'raises an error' do
          expect { sqs.find_queue('invalid') }.to raise_error(SqsWorker::Errors::NonExistentQueue)
        end
      end
    end
  end
end
