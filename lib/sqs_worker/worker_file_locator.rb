module SqsWorker
  class WorkerFileLocator

    def self.locate
      root = SqsWorker.config.worker_root

      return [] unless Dir.exists?(root)

      Dir.entries(root).select do |file_name|
        file_name.end_with?('worker.rb')
      end.reverse
    end
  end
end