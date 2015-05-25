module SqsWorker
  class WorkerFileLocator

    def self.locate
      Dir.entries(SqsWorker.config.worker_root).select do |file_name|
        file_name.end_with?('worker.rb')
      end.reverse
    end
  end
end