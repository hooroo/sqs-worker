require 'sqs_worker/signal_handler'

module SqsWorker
  class Batcher
    include Celluloid
    include SqsWorker::SignalHandler

    def initialize(manager:, processor:)
      @manager = manager
      @processor = processor
      subscribe_for_signals
    end

    def process(messages)

      successful_messages = []

      unless stopping?

        processed_results = messages.to_a.map { |message| processor.future.process(message) }

        start_time = Time.now
        processed_results.each_with_index do |result, count|

          if count > 0
            elapsed = ((Time.now - start_time) * 1000).to_i
            SqsWorker.logger.info(event_name: 'sqs_worker_processing_multiple_events_start', count: count, elapsed: elapsed)
          end

          successful_messages << result.value[:message] if result.value[:success]

          if count > 0
            elapsed = ((Time.now - start_time) * 1000).to_i
            SqsWorker.logger.info(event_name: 'sqs_worker_processing_multiple_events_finish', count: count, elapsed: elapsed)
          end
        end

      end

      manager.batch_done(successful_messages)
    end

    private

    attr_reader :manager, :processor

  end

end
