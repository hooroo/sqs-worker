require 'spec_helper'
require 'sqs_worker/sns'

module SqsWorker
  describe Sns do

    subject(:sns) { described_class.clone.instance }

    let(:aws_sns) { double(AWS::SNS, topics: topics) }
    let(:topics) { instance_double(AWS::SNS::TopicCollection ) }
    let(:topic) { instance_double(AWS::SNS::Topic, name: topic_name) }
    let(:topic_name) { 'test_topic' }

    describe '#find_topic' do

      before do
        allow(AWS::SNS).to receive(:new).and_return(aws_sns)
        allow(topics).to receive(:each).and_yield(topic)
      end

      it "returns the topic with the same name" do
        expect(sns.find_topic(topic_name).name).to eq(topic_name)
      end

      it "returns a wrapped topic instance" do
        expect(sns.find_topic(topic_name)).to be_a(Topic)
      end

      context "when the topic doesn't exist" do

        it "raises an error" do
          expect { sns.find_topic("invalid") }.to raise_error(SqsWorker::Errors::NonExistentTopic)
        end
      end
    end
  end
end