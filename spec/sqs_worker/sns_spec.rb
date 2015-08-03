require 'spec_helper'
require 'sqs_worker/sns'

module SqsWorker
  describe Sns do

    subject(:sns) { described_class.clone.instance }

    let(:aws_sns) { double(Aws::SNS, topics: topics) }
    let(:topics) { [topic, other_topic] }
    let(:topic) { instance_double(Aws::SNS::Topic, attributes: {'DisplayName' => topic_name}) }
    let(:other_topic) do
      instance_double(Aws::SNS::Topic, attributes: {'DisplayName' => 'other_topic'})
    end
    let(:wrapped_topic) { instance_double(Topic) }
    let(:topic_name) { 'test_topic' }

    let(:found_topic) { sns.find_topic(found_topic_name) }
    let(:found_topic_name) { topic_name }

    describe '#find_topic' do

      before do
        allow(Aws::SNS).to receive(:new).and_return(aws_sns)
        allow(Topic).to receive(:new).and_return(wrapped_topic)
      end

      it 'wraps the topic in a new Topic' do
        found_topic
        expect(Topic).to have_received(:new).with(topic)
      end

      it "returns the wrapped topic instance" do
        expect(found_topic).to be(wrapped_topic)
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