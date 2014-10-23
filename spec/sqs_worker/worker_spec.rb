require 'spec_helper'
require 'sqs_worker/worker'

module SqsWorker
  describe StubWorker do

    it 'configures the worker' do
      expect(StubWorker.config.queue_name).to eq 'myqueue'
    end

  end

  class StubWorker

    include Worker

    configure queue_name: 'myqueue'

  end

end
