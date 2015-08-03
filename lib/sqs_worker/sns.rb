require 'aws-sdk'
require 'singleton'
require 'sqs_worker/topic'
require 'sqs_worker/errors'

module SqsWorker
  class Sns < SimpleDelegator

    include Singleton

    def initialize
      @sns = ::Aws::SNS.new
      super(@sns)
    end

    def find_topic(topic_name)
      sns.topics.each do |topic|
        return Topic.new(topic) if topic_name == topic.attributes['DisplayName']
      end
      found_topic_names = sns.topics.map{ |topic| topic.attributes['DisplayName'] }.join(', ')
      raise SqsWorker::Errors::NonExistentTopic, "No topic found with name '#{topic_name}', found these topics: #{found_topic_names}"
    end

    private

    attr_reader :sns

  end

end


