require 'active_support/core_ext/class/attribute'

module SqsWorker
  module Worker
    module ClassMethods

      def configure(config)
        self._config = WorkerConfig.new(config)
      end

      def config
        self._config
      end

    end

    def self.included(base)
      base.send :extend,  ClassMethods
      base.class_attribute :_config
    end
  end
end


