require 'gem_publisher'
require 'rspec/core/rake_task'
task ci: :spec
task default: :ci

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = '--tag ~local_only' if ENV['CI']
end