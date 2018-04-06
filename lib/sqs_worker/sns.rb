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
      @topics = sns.topics
      super(@sns)
    end

    def find_topic(topic_name)
      topic = topics.find { |t| t.attributes['DisplayName'] == topic_name }
      return Topic.new(topic) unless topic.nil?
      raise SqsWorker::Errors::NonExistentTopic, "No topic found with name '#{topic_name}', found these topics: #{topic_names.join(', ')}"
    end

    private

    attr_reader :sns, :topics

    def topic_names
      sns.topics.map { |t| t.attributes['DisplayName'] }
    end

  end

end
