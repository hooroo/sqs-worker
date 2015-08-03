require 'spec_helper'
require 'sqs_worker/sns'

module SqsWorker
  describe Sns do

    subject(:sns) { described_class.clone.instance }

    let(:sns_client) { double(Aws::SNS::Client, list_topics: topics) }
    let(:topics) { [listed_topic, other_listed_topic] }
    let(:topic_arn) { "some:arn:#{topic_name}" }
    let(:listed_topic) do
      instance_double(Aws::SNS::Types::Topic, topic_arn: topic_arn)
    end
    let(:other_listed_topic) do
      instance_double(Aws::SNS::Types::Topic, topic_arn: 'some:arn:other_topic')
    end

    let(:wrapped_topic) { instance_double(Topic) }
    let(:topic_name) { 'test_topic' }

    let(:found_topic) { sns.find_topic(found_topic_name) }
    let(:found_topic_name) { topic_name }
    let(:aws_topic) { instance_double(Aws::SNS::Topic) }

    describe '#find_topic' do

      before do
        allow(Aws::SNS::Client).to receive(:new).and_return(sns_client)
        allow(Aws::SNS::Topic).to receive(:new).and_return(aws_topic)
        allow(Topic).to receive(:new).and_return(wrapped_topic)
      end

      context 'when the topic exists' do
        before { found_topic }

        it 'creates a new AWS topic with the found ARN and client' do
          expect(Aws::SNS::Topic).to have_received(:new).with(
            arn: topic_arn,
            client: sns_client
          )
        end

        it 'wraps the AWS topic in a new Topic' do
          expect(Topic).to have_received(:new).with(aws_topic)
        end

        it "returns the wrapped topic instance" do
          expect(found_topic).to be(wrapped_topic)
        end
      end

      context "when the topic doesn't exist" do

        describe 'the raised error' do
          let(:found_topic_name) { 'invalid' }

          it 'is a non-existent topic error' do
            expect { found_topic }.to raise_error(SqsWorker::Errors::NonExistentTopic)
          end

          it 'includes the topic name in the message' do
            expect { found_topic }.to raise_error(/invalid/)
          end

          it 'includes the names of the topics that were found in the message' do
            expect { found_topic }.to raise_error(/test_topic, other_topic/)
          end
        end
      end
    end
  end
end