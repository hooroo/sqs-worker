require 'active_support/core_ext/class/attribute'

module SqsWorker
  module Worker
    module ClassMethods

      def worker_config(config)
        self._worker_config = WorkerConfig.new(config)
      end

      def worker_config
        self._worker_config
      end

    end

    def self.included(base)
      base.send :extend,  ClassMethods
      base.class_attribute :_worker_config
    end
  end
end


