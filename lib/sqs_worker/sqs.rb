require 'aws-sdk'
require 'singleton'
require 'sqs_worker/queue'
require 'sqs_worker/errors'

module SqsWorker
  class Sqs < SimpleDelegator

    include Singleton

    def initialize
      @sqs_client = Aws::SQS::Client.new
      super(@sqs)
    end

    def find_queue(queue_name)
      url = sqs_client.get_queue_url(queue_name: queue_name).queue_url
      Queue.new(sqs_client, url, queue_name.to_s)
    rescue Aws::SQS::Errors::QueueDoesNotExist => e
      raise SqsWorker::Errors::NonExistentQueue, "No queue found with name '#{queue_name}'"
    end

    private

    attr_reader :sqs_client

  end

end


