require 'active_support/core_ext/string'

module SqsWorker

  class WorkerResolver

    def resolve_worker_classes

      workers = WorkerFileLocator.locate.map do |file_name|
        file_name.gsub('.rb','').camelize.constantize
      end

      workers += SqsWorker.config.worker_classes
      workers.select { |worker| worker.ancestors.include?(SqsWorker::Worker) }
    end

  end
end