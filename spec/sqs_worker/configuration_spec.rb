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

      context 'application root' do
        let(:application_root) { '/path/to/application' }

        before do
            subject.application_root = application_root
        end

        it 'allows the application root to be configured' do
          expect(subject.application_root).to eq(application_root)
        end
      end
    end
  end
end