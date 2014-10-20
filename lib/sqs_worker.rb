require "sqs_worker/version"
require 'celluloid'
require 'celluloid/autostart'

require "sqs_worker/manager"
require 'sqs_worker/fetcher'
require 'sqs_worker/processor'
require 'sqs_worker/deleter'
require 'sqs_worker/batch_processor'
require "sqs_worker/runner"

module SqsWorker
  # Your code goes here...
end
