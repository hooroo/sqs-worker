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
      subscribe_for_signals
    end

    def process(message)
      return { success: false, message: message } if stopping?

      result = true

      begin
        parsed_message = message_parser.parse(message)
        correlation_id = correlation_id_from(parsed_message)
        store_correlation_id(correlation_id)

        log_event('sqs_worker_received_message', message.message_id, correlation_id)
        worker_class.new.perform(parsed_message.body)
        log_event('sqs_worker_processed_message', message.message_id, correlation_id)

      rescue SqsWorker::Errors::UnrecoverableError => error
        publish(:unrecoverable_error, worker_class)
        log_exception(error)
        result = false

      rescue StandardError => error
        log_exception(error)
        result = false

      ensure
        ::ActiveRecord::Base.clear_active_connections! if defined?(::ActiveRecord)
      end

      return { success: result, message: message }
    end

    private

    attr_reader :worker_class, :message_parser

    def store_correlation_id(correlation_id)
      Thread.current[:correlation_id] = correlation_id
    end

    def correlation_id_from(message)
      message.message_attributes[:correlation_id]
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

    def log_event(event_name, message_id, correlation_id)
      SqsWorker.logger.info(event_name: event_name, type: worker_class, queue_name: worker_class.config.queue_name, message_id: message_id, correlation_id: correlation_id)
    end

  end
end
