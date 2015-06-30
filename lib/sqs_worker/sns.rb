require 'aws-sdk'
require 'singleton'
require 'sqs_worker/topic'
require 'sqs_worker/errors'

module SqsWorker
  class Sns < SimpleDelegator

    include Singleton

    def initialize
      @sns = ::AWS::SNS.new
      super(@sns)
    end

    def find_topic(topic_name)
      sns.topics.each do |topic|
        return Topic.new(topic) if topic_name == topic.name
      end
      raise SqsWorker::Errors::NonExistentTopic, "No topic found with name '#{topic_name}'"
    end

    private

    attr_reader :sns

  end

end


