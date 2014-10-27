require 'sqs_worker/signal_handler'

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
        worker_class.new.perform(message)
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

    def log_exception(exception)
      SqsWorker.logger.error({
        event_name: :sqs_worker_error,
        worker_class: worker_class.name,
        error_class: exception.class.name,
        backtrace: exception.backtrace
      })
    end

  end
end
