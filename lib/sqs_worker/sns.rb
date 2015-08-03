require 'aws-sdk'
require 'singleton'
require 'sqs_worker/topic'
require 'sqs_worker/errors'

module SqsWorker
  class Sns

    include Singleton

    def initialize
      @sns_client = ::Aws::SNS::Client.new
    end

    def find_topic(topic_name)
      found_topic_names = []
      sns_client.list_topics.each do |listed_topic|
        found_topic_names << found_topic_name = listed_topic.topic_arn.split(':').last
        return create_topic_from(listed_topic) if topic_name == found_topic_name
      end
      raise SqsWorker::Errors::NonExistentTopic, "No topic found with name '#{topic_name}', found these topics: #{found_topic_names.join(', ')}"
    end

    private

    attr_reader :sns_client

    def create_topic_from(listed_topic)
      topic = ::Aws::SNS::Topic.new(arn: listed_topic.topic_arn, client: sns_client)
      return Topic.new(topic)
    end
  end

end


