module SqsWorker
  module SignalHandler
    include Celluloid
    include Celluloid::Notifications

    def subscribe_for_signals
      subscribe('SIGINT', :shutting_down)
      subscribe('TERM', :shutting_down)
      subscribe('SIGTERM', :shutting_down)
      subscribe('USR1', :stopping)
      subscribe('SIGUSR1', :stopping)
      subscribe('USR2', :starting)
      subscribe('SIGUSR2', :starting)
    end

    # Celluloid 0.17.3 has made the #publish method private because it's flagged as a module_function
    def publish(pattern, *args)
      super
    end

    def stopping(signal)
      @stopping = true
    end
    alias_method :shutting_down, :stopping

    def starting(signal)
      @stopping = false
    end

    def stopping?
      !!@stopping
    end
    alias_method :shutting_down?, :stopping?
  end
end