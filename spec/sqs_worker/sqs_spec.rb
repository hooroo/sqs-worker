require 'spec_helper'
require 'sqs_worker/sqs'

module SqsWorker
  describe Sqs do

    subject(:sqs) { described_class.clone.instance }

    let(:queue_url) { 'http://q.com' }
    let(:get_queue_url_result) { instance_double(Aws::SQS::Types::GetQueueUrlResult, queue_url: queue_url) }
    let(:sqs_client) { double(Aws::SQS::Client, get_queue_url: get_queue_url_result) }
    let(:wrapped_queue) { instance_double(Queue)}
    let(:queue_name) { 'test_queue' }
    let(:found_queue) { sqs.find_queue(queue_name) }

    describe '#find_queue' do

      before do
        allow(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
        allow(Queue).to receive(:new).and_return(wrapped_queue)
      end

      context 'when the queue does exist' do
        before { found_queue }
        it "finds the queue URL using the correct queue name" do
          expect(sqs_client).to have_received(:get_queue_url).with(hash_including(queue_name: queue_name))
        end

        it "creates the queue with the sqs client, queue URL and queue name" do
          expect(Queue).to have_received(:new).with(sqs_client, queue_url, queue_name)
        end

        it "returns a wrapped queue instance" do
          expect(found_queue).to be(wrapped_queue)
        end
      end

      context "when the queue doesn't exist" do

        before do
          allow(sqs_client).to receive(:get_queue_url).and_raise(Aws::SQS::Errors::QueueDoesNotExist.new('', ''))
        end

        it "raises an error" do
          expect { found_queue }.to raise_error(SqsWorker::Errors::NonExistentQueue)
        end
      end
    end
  end
end