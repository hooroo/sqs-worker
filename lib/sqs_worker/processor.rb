require 'active_support/core_ext/hash/keys'
require 'sqs_worker/signal_handler'
require 'sqs_worker/message_parser'

module SqsWorker
  class Processor
    include Celluloid
    include SqsWorker::SignalHandler

    def initialize(worker_class, message_parser: MessageParser.new)
      @worker_class   = worker_class
      @message_parser = message_parser

      subscribe_for_shutdown
    end

    def process(message)
      return { success: false, message: message } if shutting_down?

      result = true
      begin
        parsed_message = message_parser.parse(message)
        store_correlation_id(parsed_message)

        log_event("sqs_worker_received_message")

        worker_class.new.perform(parsed_message.body)

        log_event("sqs_worker_processed_message")

      rescue Exception => exception
        log_exception(exception)
        fire_error_handlers(exception)
        result = false

      ensure
        ::ActiveRecord::Base.clear_active_connections! if defined?(::ActiveRecord)
      end

      { success: result, message: message }
    end

    private

    attr_reader :worker_class, :message_parser

    def store_correlation_id(message)
      Thread.current[:correlation_id] = message.message_attributes[:correlation_id]
    end

    def fire_error_handlers(exception)
      if worker_class.config.error_handlers
        worker_class.config.error_handlers.each do |handler|
          handler.call(exception, worker_class) rescue nil
        end
      end
    end

    def log_exception(exception)
      SqsWorker.logger.error(
          event_name:   :sqs_worker_processor_error,
          queue_name:   worker_class.config.queue_name,
          worker_class: worker_class.name,
          error_class:  exception.class.name,
          exception:    exception,
          backtrace:    exception.backtrace
      )
    end

    def log_event(event_name)
      SqsWorker.logger.info(
          event_name: event_name,
          type:       worker_class,
          queue_name: worker_class.config.queue_name
      )
    end
  end
end
