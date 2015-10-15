module SqsWorker
  class WorkerConfig

    MIN_PROCESSORS = 10
    MIN_POOL_SIZE = 2
    DEFAULT_EMPTY_QUEUE_THROTTLE = 2
    MAX_FETCH_BATCH_SIZE = 10

    attr_reader :num_processors, :num_fetchers, :num_batchers, :num_deleters, :fetcher_batch_size, :queue_name, :empty_queue_throttle

    def initialize(config)

      raise 'You must specify a queue name for all SqsWorker classes.' unless config[:queue_name]

      num_processors = [config[:processors].to_i, MIN_PROCESSORS].max

      @num_processors = num_processors
      @num_fetchers = MIN_POOL_SIZE
      @num_batchers = MIN_POOL_SIZE
      @num_deleters = MIN_POOL_SIZE
      @queue_name = config[:queue_name]
      @empty_queue_throttle = config[:empty_queue_throttle] || DEFAULT_EMPTY_QUEUE_THROTTLE
      @fetcher_batch_size = [(@num_processors / @num_fetchers).to_i, MAX_FETCH_BATCH_SIZE].min

    end

  end
end
