require 'spec_helper'
require 'sqs_worker/worker'

module SqsWorker
  describe Worker do

    let(:global_config) { double('global config', queue_name: 'globally_configured_queue' ) }

    before do
      allow(SqsWorker.config).to receive(:worker_configurations).and_return(
        GloballyConfiguredWorker => global_config,
        ClassConfiguredWorker => global_config
      )
    end

    describe '.config' do
      context 'when worker is not configured from within the class' do
        it 'returns the SqsWorker global configuration' do
          expect(GloballyConfiguredWorker.config.queue_name).to eq('globally_configured_queue')
        end
      end

      context 'when the worker is configured both within the class and globally' do
        it 'returns the class configuration instead of the global configuration' do
          expect(ClassConfiguredWorker.config.queue_name).to eq('class_configured_queue')
        end
      end
    end
  end

  class ClassConfiguredWorker
    include Worker
    configure queue_name: 'class_configured_queue'
  end

  class GloballyConfiguredWorker
    include Worker
  end
end
