module SqsWorker
  module Errors
    class SqsWorkerError < StandardError; end
    class NonExistentTopic < SqsWorkerError; end
    class NonExistentQueue < SqsWorkerError; end
    class MessageFormat < SqsWorkerError; end
  end
end