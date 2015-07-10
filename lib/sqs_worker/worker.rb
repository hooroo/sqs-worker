require 'active_support/core_ext/class/attribute'

module SqsWorker
  module Worker
    module ClassMethods
      def configure(configuration)
        @config = WorkerConfig.new(configuration)
      end

      def config
        @config || SqsWorker.config.worker_configurations[self]
      end

    end

    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    def config
      self.class.config
    end
  end
end


