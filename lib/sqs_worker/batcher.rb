require 'sqs_worker/signal_handler'

module SqsWorker
  class Batcher
    include Celluloid
    include SqsWorker::SignalHandler

    def initialize(manager:, processor:)
      @manager = manager
      @processor = processor
      subscribe_for_shutdown
    end

    def process(messages)

      successful_messages = []

      unless shutting_down?

        processed_results = messages.to_a.map { |message| processor.future.process(message) }

        processed_results.each do |result|
          successful_messages << result.value[:message] if result.value[:success]
        end

      end

      manager.batch_done(successful_messages)
    end

    private

    attr_reader :manager, :processor

  end

end
