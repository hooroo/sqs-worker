require_relative 'integration_spec_helper'

describe "failures to contact sqs" do
  let!(:fake_sqs) { FakeSqs.new }

  let(:fail_times) { 10 }
  let(:logger) { Logger.new(StringIO.new) }

  let(:worker_class) do
    StubWorker.config

    StubWorker
  end

  let(:manager) { SqsWorker::Manager.new(worker_class: worker_class, heartbeat_monitor: NullHeartbeatMonitor.new) }

  before do
    worker_class.reset

    SqsWorker.logger = logger
    Celluloid.logger = logger
  end

  describe 'when it is intermittently failing to fetch messages' do
    before do
      fake_sqs.will_fail_to_fetch_messages(fail_times)
      manager.start
    end

    it 'will recover after sqs is restored' do
      wait_for { worker_class.call_count }.to be > 1
    end
  end

  describe 'when it is intermittently failing to delete messages' do
    before do
      fake_sqs.will_fail_to_delete_messages(fail_times)
      manager.start
    end

    it 'will recover after sqs is restored' do
      wait_for { fake_sqs.delete_call_count }.to be > 1
    end
  end

  describe 'when the worker fails' do
    let(:worker_class) do
      FailingStubWorker.config

      FailingStubWorker
    end

    before do
      manager.start
    end

    it 'will keep on going after many worker failures' do
      wait_for { worker_class.call_count }.to be > 100
    end
  end
end