require 'sqskiq/signal_handler'

module SqsWorker
  class BatchProcessor
    include Celluloid
    include SqsWorker::SignalHandler

    def initialize(manager:, processor:)
      @manager = manager
      @processor = processor
      subscribe_for_shutdown
    end

    def process(messages)
      process_result = []
      messages.each do |message|
        process_result << processor.future.process(message)
      end

      success_messages = []
      process_result.each do |result|

        unless shutting_down
          value = result.value
          if value[:success]
            success_messages << value[:message]
          end
        end
      end

      manager.batch_done(success_messages)
    end

    private

    attr_reader :manager, :processor

  end

end
