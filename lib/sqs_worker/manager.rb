require 'sqs_worker/signal_handler'
require 'sqs_worker/worker_config'
require 'sqs_worker/fetcher'
require 'sqs_worker/processor'
require 'sqs_worker/deleter'
require 'sqs_worker/batcher'

module SqsWorker
  class Manager
    include Celluloid
    include SqsWorker::SignalHandler

    attr_reader :worker_class

    def initialize(worker_class)

      @config = worker_class.config
      @empty_queue_throttle = config.empty_queue_throttle
      @worker_class = worker_class
      @empty_queue = false

      subscribe_for_shutdown
    end

    def start
      logger.info(event_name: "sqs_worker_starting_manager", type: worker_class, queue_name: worker_class.config.queue_name)
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
      SqsWorker.logger.info(event_name: "sqs_worker_prepare_for_shutdown", type: worker_class)
      self.publish('SIGTERM')
      batcher.publish('SIGTERM')
      processor.publish('SIGTERM')
    end

    private

    attr_reader :config, :empty_queue_throttle
    attr_accessor :empty_queue

    def processor
      @processor ||= Processor.pool(size: config.num_processors, args: worker_class)
    end

    def fetcher
      @fetcher ||= Fetcher.pool(size: config.num_fetchers, args: [{ queue_name: config.queue_name, manager: self, batch_size: config.fetcher_batch_size }])
    end

    def deleter
      @deleter ||= Deleter.pool(size: config.num_deleters, args: [config.queue_name])
    end

    def batcher
      @batcher ||= Batcher.pool(size: config.num_batchers, args: [{ manager: self, processor: processor }])
    end

    def throttle
      empty_queue ? empty_queue_throttle : 0
    end

    def logger
      SqsWorker.logger
    end

  end
end