require 'spec_helper'
require 'sqs_worker/worker_resolver'

class LocatedTestWorker
  include SqsWorker::Worker
end

class ConfiguredTestWorker
  include SqsWorker::Worker
end

class IgnoredLocatedTestWorker; end
class IgnoredConfiguredTestWorker; end

module SqsWorker

  describe WorkerResolver do

    describe '#resolve_worker_classes' do

      let(:resolved_classes) { subject.resolve_worker_classes }

      before do
        allow(WorkerFileLocator).to receive(:locate).and_return(
          %w(located_test_worker.rb ignored_located_test_worker.rb)
        )
        allow(SqsWorker.config).to receive(:worker_classes).and_return(
          [ConfiguredTestWorker, IgnoredConfiguredTestWorker]
        )
      end

      it 'includes workers defined in the located worker files' do
        expect(resolved_classes).to include(LocatedTestWorker)
      end

      it 'includes the workers added via configuration' do
        expect(resolved_classes).to include(ConfiguredTestWorker)
      end

      it 'only includes worker classes that are actual workers' do
        expect(resolved_classes).to_not include(IgnoredLocatedTestWorker)
        expect(resolved_classes).to_not include(IgnoredConfiguredTestWorker)
      end
    end
  end
end