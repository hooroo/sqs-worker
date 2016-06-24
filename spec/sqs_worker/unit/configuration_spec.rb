require 'spec_helper'

class MyTestWorker;
end

module SqsWorker
  describe Configuration do
    describe 'configuration' do

      context 'worker classes' do
        before do
          subject.worker_classes << MyTestWorker
        end

        it 'allows worker classes to be configured' do
          expect(subject.worker_classes).to eq([MyTestWorker])
        end
      end

      context 'worker root' do

        context 'when a worker root is configured' do
          let(:worker_root) { '/path/to/workers' }

          before do
            subject.worker_root = worker_root
          end

          it 'is the given worker root' do
            expect(subject.worker_root).to eq(worker_root)
          end
        end

        context 'when no worker root is configured' do
          it 'is app/workers' do
            expect(subject.worker_root).to eq('app/workers')
          end
        end
      end

      context 'configuring workers' do

        let(:worker_class) { Class.new }

        before do
          subject.add_worker_configuration(worker_class, queue_name: 'my_queue')
        end

        it 'creates a new worker configuration for each worker configured' do
          expect(subject.worker_configurations[worker_class].queue_name).to eq('my_queue')
        end
      end
    end
  end
end