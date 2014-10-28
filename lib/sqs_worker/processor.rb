require 'active_support/core_ext/hash/keys'
require 'sqs_worker/signal_handler'
require 'json'

module SqsWorker
  class Processor
    include Celluloid
    include SqsWorker::SignalHandler

    def initialize(worker_class)
      @worker_class = worker_class
      subscribe_for_shutdown
    end

    def process(message)

      return  { success: false, message: message } if shutting_down?

      result = true

      begin
        parsed_message = parse_message(message)

        store_correlation_id(parsed_message)
        worker_class.new.perform(parsed_message.body)
        SqsWorker.logger.info(event_name: "sqs_worker_processed_message", type: worker_class)
      rescue Exception => exception
        log_exception(exception)
        result = false
      ensure
        ::ActiveRecord::Base.clear_active_connections! if defined?(::ActiveRecord)
      end

      return { success: result, message: message }

    end

    private

    attr_reader :worker_class

    def store_correlation_id(message)
      Thread.current[:correlation_id] = message.message_attributes[:correlation_id]
    end

    def log_exception(exception)
      SqsWorker.logger.error({
        event_name: :sqs_worker_processor_error,
        worker_class: worker_class.name,
        error_class: exception.class.name,
        exception: exception,
        backtrace: exception.backtrace
      })
    end

    #make messages look like they would with sdk v2.x
    def parse_message(message)
      parsed_message = JSON.parse(message.body).deep_symbolize_keys
      OpenStruct.new(body: parsed_message[:body], message_attributes: parsed_message[:message_attributes])
    end

  end
end
