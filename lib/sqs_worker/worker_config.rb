module SqsWorker
  class WorkerConfig

    MIN_PROCESSORS = 20
    MIN_POOL_SIZE = 2
    DEFAULT_EMPTY_QUEUE_THROTTLE = 5

    attr_reader :num_processors, :num_fetchers, :num_batchers, :num_deleters, :queue_name, :empty_queue_throttle

    def initialize(config)

      raise "You must specify a queue name for all SqsWorker classes." unless config[:queue_name]

      num_processors = [config[:processors].to_i, MIN_PROCESSORS].max
      num_fetchers = [(num_processors / Fetcher::MESSAGE_FETCH_LIMIT).to_i, MIN_POOL_SIZE].max
      num_deleters = num_batchers = num_fetchers

      @num_processors = num_processors
      @num_fetchers = num_fetchers
      @num_batchers = num_batchers
      @num_deleters = num_deleters
      @queue_name = config[:queue_name]
      @empty_queue_throttle = config[:empty_queue_throttle] || DEFAULT_EMPTY_QUEUE_THROTTLE

    end

  end
end