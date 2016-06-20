module SqsWorker
  module Heartbeat
    class LogFileHeartbeatMonitor

      HEARTBEAT = 'sqs_worker is alive'

      def initialize(logger:, threshold_seconds:)
        @logger = logger
        @threshold_seconds = threshold_seconds

        @mutex = Mutex.new
      end

      def tick
        @mutex.synchronize do
          if time_for_a_new_heartbeat?
            logger.info(HEARTBEAT)
            self.last_heartbeat_time = DateTime.now
          end
        end
      end

      private
      attr_reader :logger,
                  :threshold_seconds

      attr_accessor :last_heartbeat_time


      def time_for_a_new_heartbeat?
        return true unless last_heartbeat_time


        DateTime.now > last_heartbeat_time + threshold_days
      end

      def threshold_days
        Rational(threshold_seconds, 86400)
      end
    end
  end
end

