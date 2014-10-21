require 'celluloid/test'
require 'sqs_worker'
require 'pry'


# require "codeclimate-test-reporter"
# CodeClimate::TestReporter.start

RSpec.configure do |config|

  config.order = "random"

  config.before(:each) do
    puts 'Booting celuloid'
    Celluloid.boot
  end

  config.after(:each) do
    Celluloid.shutdown
  end

end