require 'json'
require 'active_support/core_ext/class/attribute'

module SqsWorker
  module Worker
    module ClassMethods
      def connection
        puts 'SqsWorker config:'
        puts SqsWorker.configuration
        @sqs ||= ::AWS::SQS.new(SqsWorker.configuration)
      end

      def current_queue
        connection.queues.
          named(self.sqs_worker_options_hash[:queue_name].to_s)
      end

      def size
        current_queue.approximate_number_of_messages
      end

      def perform_async(params)
        current_queue.send_message params.to_json
      end

      def run
        SqsWorker.bootstrap(sqs_worker_options_hash, self)
      end

      def sqs_worker_options(options)
        self.sqs_worker_options_hash = options
      end
    end

    def self.included(base)
      base.send :extend,  ClassMethods
      base.class_attribute :sqs_worker_options_hash
    end
  end
end
