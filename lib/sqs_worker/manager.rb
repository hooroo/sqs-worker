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

    def initialize(worker_class:, heartbeat_monitor:)
      @config               = worker_class.config
      @empty_queue_throttle = config.empty_queue_throttle
      @worker_class         = worker_class
      @empty_queue          = false
      @heartbeat_monitor    = heartbeat_monitor

      subscribe_for_signals
      subscribe(:unrecoverable_error, :handle_unrecoverable_error)
    end

    def handle_unrecoverable_error(signal, worker_class)
      shutting_down(signal) if self.worker_class == worker_class
    end

    def prepare_to_start
      verify_queue_is_accessible!
    end

    def start
      logger.info(event_name: 'sqs_worker_starting_manager', type: worker_class, queue_name: worker_class.config.queue_name)
      fetch_messages(fetcher.size)
    end

    def fetch_messages(num)
      after(throttle) do
        num.times { fetcher.async.fetch unless shutting_down? }
      end
    end

    def fetch_done(messages)
      heartbeat_monitor.tick

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
      SqsWorker.logger.info(event_name: 'sqs_worker_prepare_for_shutdown', type: worker_class, queue_name: worker_class.config.queue_name)
      [self, batcher, processor].each { |receiver| receiver.publish('SIGTERM') }
    end

    def soft_stop
      SqsWorker.logger.info(event_name: 'sqs_worker_soft_stop', type: worker_class, queue_name: worker_class.config.queue_name)
      [self, batcher, processor].each { |receiver| receiver.publish('SIGUSR1') }
    end

    def soft_start
      SqsWorker.logger.info(event_name: 'sqs_worker_soft_start', type: worker_class, queue_name: worker_class.config.queue_name)
      [self, batcher, processor].each { |receiver| receiver.publish('SIGUSR2') }
      fetch_messages(fetcher.size)
    end

    private

    attr_reader :config, :empty_queue_throttle, :heartbeat_monitor
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

    def verify_queue_is_accessible!
      Sqs.instance.find_queue(worker_class.config.queue_name)
    rescue SqsWorker::Errors::NonExistentQueue => e
      SqsWorker.logger.info(event_name: 'sqs_worker_queue_not_found', type: worker_class, queue_name: worker_class.config.queue_name)
      raise e
    end

  end
end
