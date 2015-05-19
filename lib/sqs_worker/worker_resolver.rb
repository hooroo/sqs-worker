require 'active_support/core_ext/string'

module SqsWorker

  class WorkerResolver

    def resolve_worker_classes

      WorkerFileLocator.locate.inject([]) do |workers, file_name|
        worker_class = file_name.gsub('.rb','').camelize.constantize

        if worker_class.ancestors.include?(SqsWorker::Worker)
          workers << worker_class
        end

        workers
      end
    end

  end
end