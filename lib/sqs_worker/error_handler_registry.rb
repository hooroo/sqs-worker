module SqsWorker

  module ErrorHandlerRegistry
    def register(error_handler)
      error_handlers << error_handler unless error_handlers.member?(error_handler)
    end

    def each(&block)
      error_handlers.each
    end

    def error_handlers
      @error_handlers ||= []
    end

    extend self
  end
end
