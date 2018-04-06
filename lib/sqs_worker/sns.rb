require 'aws-sdk-sns'
require 'singleton'
require 'sqs_worker/topic'
require 'sqs_worker/errors'

module SqsWorker
  class Sns < SimpleDelegator

    include Singleton

    def initialize
      Aws.config.update({ log_level: :debug })
      @sns = ::Aws::SNS.Resource.new(logger: SqsWorker.logger)
      @topics = sns.topics.entries
      super(@sns)
    end

    def find_topic(topic_name)
      sns.create_topic({ name: topic_name })
    end

    private

    attr_reader :sns, :topics

  end

end
