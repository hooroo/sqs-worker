module SqsWorker
  class WorkerFileLocator

    def self.locate
      Dir.entries(Rails.root.join('app', 'workers')).select do |file_name|
        file_name.end_with?('worker.rb')
      end.reverse
    end
  end
end