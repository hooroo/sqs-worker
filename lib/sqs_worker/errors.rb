module SqsWorker
  module Errors
    class SqsWorkerError < StandardError; end
    class NonExistentTopic < SqsWorkerError; end
    class NonExistentQueue < SqsWorkerError; end
  end
end