class FailingStubWorker
  include SqsWorker::Worker
  include Celluloid

  def self.config
    SqsWorker::WorkerConfig.new(queue_name: 'fakey2', empty_queue_throttle: 0)
  end

  def perform(*args)
    self.class.inc_called

    raise "bad shit"
  end

  def self.reset
    @called = 0
  end

  def self.call_count
    @called
  end

  def self.inc_called
    @called += 1
  end
end