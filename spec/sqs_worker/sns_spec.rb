require 'spec_helper'
require 'sqs_worker/sns'

module SqsWorker
  describe Sns do

    subject(:sns) { described_class.clone.instance }

    let(:aws_sns) { double(AWS::SNS, topics: topics) }
    let(:logger) { double('logger') }
    let(:topics) { [topic, other_topic] }
    let(:topic) { instance_double(AWS::SNS::Topic, name: topic_name) }
    let(:other_topic) { instance_double(AWS::SNS::Topic, name: 'other_topic') }
    let(:topic_name) { 'test_topic' }

    describe '#find_topic' do

      before do
        allow(SqsWorker).to receive(:logger).and_return(logger)
        allow(AWS::SNS).to receive(:new).and_return(aws_sns)
      end

      it 'returns the topic with the same name' do
        expect(sns.find_topic(topic_name).name).to eq(topic_name)
      end

      it 'returns a wrapped topic instance' do
        expect(sns.find_topic(topic_name)).to be_a(Topic)
      end

      context "when the topic doesn't exist" do

        describe 'the raised error' do
          let(:find_invalid) { sns.find_topic('invalid') }

          it 'is a non-existent topic error' do
            expect { find_invalid }.to raise_error(SqsWorker::Errors::NonExistentTopic)
          end

          it 'includes the topic name in the message' do
            expect { find_invalid }.to raise_error(/invalid/)
          end

          it 'includes the names of the topics that were found in the message' do
            expect { find_invalid }.to raise_error(/test_topic, other_topic/)
          end
        end
      end
    end
  end
end
