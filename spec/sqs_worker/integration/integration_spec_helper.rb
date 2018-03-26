require 'webmock'
require 'spec_helper'
require 'webmock/rspec'
require "rspec/wait"

WebMock.disable_net_connect!(:allow_localhost => true)

require_relative '../support/fake_sqs'
require_relative '../support/null_heartbeat_monitor'
require_relative '../support/stub_worker'
require_relative '../support/failing_stub_worker'

Aws.config.update({
  use_ssl: false,
  sqs_endpoint: "localhost",
  sqs_port: 4568,
  access_key_id: "fake access key",
  secret_access_key: "fake secret key"
})

RSpec.configure do |config|
  config.before(:each) do
    SqsWorker.config.worker_configurations.clear
  end
end

