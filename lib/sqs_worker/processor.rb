require 'sqs_worker/signal_handler'

module SqsWorker
  class Processor
    include Celluloid
    include SqsWorker::SignalHandler

    def initialize(worker_class)
      @worker_instance = worker_class.new
      subscribe_for_shutdown
    end

    def process(message)
      return  { :success => false, :message => message } if shutting_down?

      result = true

      begin
        worker_instance.perform(message)
      rescue Exception => e
        result = false
      ensure
        ::ActiveRecord::Base.clear_active_connections! if defined?(::ActiveRecord)
      end

      return { :success => result, :message => message }

    end

    private

    attr_reader :worker_instance

  end
end
