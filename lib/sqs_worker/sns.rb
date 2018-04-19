require 'aws-sdk-sns'
require 'singleton'
require 'sqs_worker/topic'
require 'sqs_worker/errors'

module SqsWorker
  class Sns < SimpleDelegator

    include Singleton

    def initialize
      Aws.config.update({ log_level: :debug })
      @sns = ::Aws::SNS::Resource.new(logger: SqsWorker.logger)
      @topics = fetch_topics
      super(@sns)
    end

    def find_topic(topic_name)
      topic = topics[topic_name]
      return Topic.new(topic) unless topic.nil?

      raise SqsWorker::Errors::NonExistentTopic, "No topic found with name '#{topic_name}', found these topics: #{topics.keys.sort.join(', ')}"
    end

    private

    attr_reader :sns, :topics

    def fetch_topics
      sns.topics.each_with_object({}) { |topic, hsh| hsh[topic_name(topic.arn)] = topic }
    end

    def topic_name(topic_arn)
      topic_arn.split(/:/).last
    end

  end
end
