if defined?(Airbrake)
  proc = Proc.new { |exception| Airbrake.notify(exception) }
  SqsWorker::ErrorHandlerRegistry.register(proc)
end

if defined?(Honeybadger)
  proc = Proc.new { |exception| Honeybadger.notify(exception) }
  SqsWorker::ErrorHandlerRegistry.register(proc)
end

if defined?(ActiveRecord)
  proc = Proc.new { |_exception| ActiveRecord::Base.clear_active_connections! }
  SqsWorker::ErrorHandlerRegistry.register(proc)
end
