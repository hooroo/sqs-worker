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
      self.shutting_down = true
    end

    private

    attr_accessor :shutting_down

  end
end