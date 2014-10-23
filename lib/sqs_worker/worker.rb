require 'active_support/core_ext/class/attribute'

module SqsWorker
  module Worker
    module ClassMethods

      def configure(config)
        self.config = WorkerConfig.new(config)
      end

    end

    def self.included(base)
      base.send :extend,  ClassMethods
      base.class_attribute :config
    end
  end
end


