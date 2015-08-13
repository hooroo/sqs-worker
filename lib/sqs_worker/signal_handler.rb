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