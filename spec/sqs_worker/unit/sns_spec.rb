require 'spec_helper'
require 'sqs_worker/sns'

module SqsWorker
  describe Sns do

    subject(:sns) { described_class.clone.instance }

    let(:aws_sns) { double(Aws::SNS::Resource, topics: topics) }
    let(:topics) { [first_topic, second_topic] }
    let(:first_topic) { instance_double(Aws::SNS::Topic, arn: "first-arn:#{first_topic_name}") }
    let(:first_topic_name) { 'first-topic-name' }
    let(:second_topic) { instance_double(Aws::SNS::Topic, arn: "second-arn:#{second_topic_name}") }
    let(:second_topic_name) { 'second-topic-name' }

    describe '#find_topic' do

      before do
        allow(Aws::SNS::Resource).to receive(:new).and_return(aws_sns)
      end

      it 'returns the topic with the first name' do
        expect(sns.find_topic(first_topic_name)).to eq(first_topic)
      end

      it 'returns a wrapped topic instance' do
        expect(sns.find_topic(first_topic_name)).to be_a(SqsWorker::Topic)
      end

      it 'returns the topic with the second name' do
        expect(sns.find_topic(second_topic_name)).to eq(second_topic)
      end

      it 'returns a wrapped topic instance' do
        expect(sns.find_topic(second_topic_name)).to be_a(SqsWorker::Topic)
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
            expect { find_invalid }.to raise_error(/#{first_topic_name}, #{second_topic_name}/)
          end
        end
      end
    end
  end
end
