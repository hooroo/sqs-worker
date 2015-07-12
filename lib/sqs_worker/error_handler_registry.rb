require 'singleton'

module SqsWorker
  class ErrorHandlerRegistry
    include Singleton

    attr_reader :error_handlers

    def initialize
      @error_handlers = Set[]
    end

    class << self
      def register(error_handlers)
        instance.error_handlers.merge(Array(error_handlers))
      end

      def each(&block)
        instance.error_handlers.each(&block)
      end

      def handlers
        instance.error_handlers
      end

      def empty?
        handlers.count == 0
      end
    end
  end
end

require 'sqs_worker/error_handlers'
