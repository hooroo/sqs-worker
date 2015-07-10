require 'sqs_worker/worker_config'

module SqsWorker
  class Configuration
    def initialize
      @worker_classes        = []
      @worker_configurations = {}
      @worker_root           = 'app/workers'
    end

    attr_reader :worker_classes, :worker_configurations
    attr_accessor :worker_root

    def add_worker_configuration(worker_class, config)
      worker_configurations[worker_class] = WorkerConfig.new(config)
    end
  end
end
