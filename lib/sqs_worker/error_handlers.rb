SqsWorker::ErrorHandlerRegistry.register(Proc.new do |e|
  Airbrake.notify(exception)
end) if defined?(Airbrake)

SqsWorker::ErrorHandlerRegistry.register(Proc.new do |e|
  ActiveRecord::Base.clear_active_connections!
end)if defined?(ActiveRecord)
