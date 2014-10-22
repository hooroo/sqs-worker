require 'sqs_worker/signal_handler'
require 'sqs_worker/worker_config'
require 'sqs_worker/fetcher'
require 'sqs_worker/processor'
require 'sqs_worker/deleter'
require 'sqs_worker/batch_processor'

module SqsWorker
  class Manager
    include Celluloid
    include SqsWorker::SignalHandler

    def initialize(worker_class)

      config = WorkerConfig.new(worker_class)

      @empty_queue = false
      @empty_queue_throttle = config.empty_queue_throttle

      @processor = Processor.pool(size: config.num_processors, args: worker_class)
      @fetcher = Fetcher.pool(size: config.num_fetchers, args: [{ queue_name: config.queue_name, configuration: SqsWorker.configuration, manager: self }])
      @deleter = Deleter.pool(size: config.num_deleters, args: [{ queue_name: config.queue_name, configuration: SqsWorker.configuration }])
      @batcher = BatchProcessor.pool(size: config.num_batchers, args: [{ manager: self, processor: @processor }])

      subscribe_for_shutdown

    end

    def bootstrap
      fetch_messages(fetcher.size)
    end

    def fetch_messages(num)
      after(throttle) do
        num.times { fetcher.async.fetch unless shutting_down? }
      end
    end

    def fetch_done(messages)
      self.empty_queue = messages.empty?
      batcher.async.process(messages) unless shutting_down?
    end

    def batch_done(messages)
      deleter.async.delete(messages)
      fetch_messages(1)
    end

    def running?
      !shutting_down? || deleter.busy_size > 0 || batcher.busy_size > 0
    end

    def prepare_for_shutdown
      self.publish('SIGTERM')
      batcher.publish('SIGTERM')
      processor.publish('SIGTERM')
    end

    private

    attr_reader :batcher, :fetcher, :processor, :deleter, :empty_queue_throttle
    attr_accessor :empty_queue    

    def throttle
      empty_queue ? empty_queue_throttle : 0
    end

  end
end