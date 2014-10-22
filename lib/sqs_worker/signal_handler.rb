module SqsWorker
  module SignalHandler
    include Celluloid
    include Celluloid::Notifications

    def subscribe_for_shutdown
      subscribe('SIGINT', :shutting_down)
      subscribe('TERM', :shutting_down)
      subscribe('SIGTERM', :shutting_down)
    end

    def shutting_down(signal)
      @shutting_down = true
    end

    def shutting_down?
      !!@shutting_down
    end

  end
end