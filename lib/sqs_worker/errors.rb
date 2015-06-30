module SqsWorker
  module Errors
    class SqsWorkerError < StandardError; end
    class TopicDoesNotExistError < SqsWorkerError; end
  end
end