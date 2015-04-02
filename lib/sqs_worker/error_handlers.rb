SqsWorker::ErrorHandlerRegistry.register(Proc.new do |exception|
  Airbrake.notify(exception)
end) if defined?(Airbrake)

SqsWorker::ErrorHandlerRegistry.register(Proc.new do |exception|
  ActiveRecord::Base.clear_active_connections!
end)if defined?(ActiveRecord)
