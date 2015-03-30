SqsWorker::WorkerConfig::DEFAULT_ERROR_HANDLERS << Proc.new do |e|
  Airbrake.notify(exception)
end if defined?(Airbrake)

SqsWorker::WorkerConfig::DEFAULT_ERROR_HANDLERS << Proc.new do |e|
  ActiveRecord::Base.clear_active_connections!
end if defined?(ActiveRecord)
