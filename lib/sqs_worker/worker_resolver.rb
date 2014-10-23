module SqsWorker
  class WorkerResolver

    def resolve_worker_classes

      worker_file_names.inject([]) do |workers, file_name|

        worker_class = file_name.gsub('.rb','').camelize.constantize

        if worker_class.ancestors.include?(SqsWorker::Worker)
          workers << worker_class
        end

        workers
      end
    end

    private

    def worker_file_names
      Dir.entries(Rails.root.join('app', 'workers')).select { |file_name| file_name.end_with?('worker.rb') }.reverse
    end

  end
end