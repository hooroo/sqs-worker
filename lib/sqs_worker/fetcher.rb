require 'sqs_worker/aws'

module SqsWorker
  class Fetcher
    include Celluloid
    include SqsWorker::AWS

    def initialize(queue_name:, configuration: {}, manager:)
      init_queue(queue_name, configuration)
      @manager = manager
    end

    def fetch
      messages = fetch_sqs_messages
      manager.fetch_done(messages)
    end

    private

    attr_reader :manager

  end
end
