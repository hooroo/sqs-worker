require 'sqs_worker/manager'
require 'sqs_worker/worker_resolver'
require 'sqs_worker/heartbeat/log_file_heartbeat_monitor'

module SqsWorker
  class Runner

    HEARTBEAT_THRESHOLD = 60

    def self.run_all
      new.run_all
    end

    def run_all
      trap_signals

      prepare_to_start_processing
      start_processing

      while true
        handle_signals
        sleep 1
      end

    rescue Interrupt
      exit 0
    end

    def shutdown
      managers.each(&:prepare_for_shutdown)
      while managers.any?(&:running?)
        sleep 1
      end
      managers.each do |manager|
        SqsWorker.logger.info(event_name: 'sqs_worker_shutdown_complete', type: manager.worker_class)
      end
      managers.each(&:terminate)
    end


    private

    def prepare_to_start_processing
      managers.each(&:prepare_to_start)
    end

    def start_processing
      managers.each(&:start)
    end

    def restart_processing
      managers.each(&:soft_start)
    end

    def stop_processing
      managers.each(&:soft_stop)

      running_managers = managers.select(&:running?)
      until running_managers.empty?
        running_managers.each do |manager|
          SqsWorker.logger.info(event_name: 'sqs_worker_still_running', type: manager.worker_class)
        end
        sleep 0.1
        running_managers = managers.select(&:running?)
      end

      SqsWorker.logger.info(event_name: 'sqs_worker_soft_stop_complete', type: 'SqsWorker::Runner')
    end

    def managers
      @managers ||= worker_classes.map { |worker_class| Manager.new(worker_class: worker_class, heartbeat_monitor: heartbeat_monitor) }
    end

    def worker_classes
      @worker_classes ||= WorkerResolver.new.resolve_worker_classes
    end

    def heartbeat_monitor
      @heartbeat_monitor ||= Heartbeat::LogFileHeartbeatMonitor.new(logger: SqsWorker.heartbeat_logger,
                                                                    threshold_seconds: HEARTBEAT_THRESHOLD)
    end

    def trap_signals
      @signals ||= []
      %w(INT TERM USR1 USR2).each do |sig|
        Signal.trap(sig) do
          @signals << sig
        end
      end
    end

    def handle_signals
      while sig = @signals.shift
        case sig
          when 'USR1'
            stop_processing
          when 'USR2'
            restart_processing
          when 'TERM'
            shutdown
            raise Interrupt, 'Shutting down!'
          when 'INT'
            shutdown
            raise Interrupt, 'Shutting down!'
        end
      end
    end

  end


end
