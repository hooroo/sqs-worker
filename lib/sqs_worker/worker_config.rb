module SqsWorker
  class WorkerConfig

    attr_reader :num_processors, :num_fetchers, :num_batchers, :num_deleters, :queue_name, :empty_queue_throttle

    def initialize(worker_class)

      worker_config = worker_class.sqs_worker_options_hash
      num_processors = (worker_config[:processors].nil? || worker_config[:processors].to_i < 2) ? 20 : worker_config[:processors]
      # messy code due to celluloid pool constraint of 2 as min pool size: see spec for better understanding
      num_fetchers = num_processors / 10
      num_fetchers = num_fetchers + 1 if num_processors % 10 > 0
      num_fetchers = 2 if num_fetchers < 2
      num_deleters = num_batchers = num_fetchers


      @num_processors = num_processors
      @num_fetchers = num_fetchers
      @num_batchers = num_batchers
      @num_deleters = num_deleters
      @queue_name = worker_config[:queue_name]
      @empty_queue_throttle = worker_config[:empty_queue_throttle] || 0

    end

  end
end