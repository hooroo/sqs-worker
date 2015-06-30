require 'celluloid/test'
require 'sqs_worker'
require 'byebug'


# require "codeclimate-test-reporter"
# CodeClimate::TestReporter.start

# AWS.config({
#   use_ssl: false,
#   sqs_endpoint: "localhost",
#   sqs_port: 4568,
#   access_key_id: "fake access key",
#   secret_access_key: "fake secret key"
# })


RSpec.configure do |config|

  config.order = "random"

  config.before(:each) do
    Celluloid.boot
  end

  config.after(:each) do
    Celluloid.shutdown
  end

end