require 'aws-sdk-v1'
require 'singleton'
require 'sqs_worker/topic'
require 'sqs_worker/errors'

module SqsWorker
  class Sns < SimpleDelegator

    include Singleton

    def initialize
      @sns = ::AWS::SNS.new(logger: SqsWorker.logger)
      super(@sns)
    end

    def find_topic(topic_name)
      sns.topics.each do |topic|
        return Topic.new(topic) if topic_name == topic.name
      end
      raise SqsWorker::Errors::NonExistentTopic, "No topic found with name '#{topic_name}', found these topics: #{sns.topics.map(&:name).join(', ')}"
    end

    private

    attr_reader :sns

  end

end
