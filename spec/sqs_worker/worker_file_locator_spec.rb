require 'spec_helper'
require 'sqs_worker/worker_file_locator'

module SqsWorker

  class Rails;end # we shouldn't refer to Rails root as the rest of SQS worker is not rails specific

  describe WorkerFileLocator do

    describe '#self.locate' do

      let(:located_files) { described_class.locate }

      before do
        allow(Rails).to receive(:root).and_return(Pathname.new('rails_root'))
        allow(Dir).to receive(:entries).and_return(
          %w(first_test_worker.rb second_test_worker.rb invalid.rb)
        )
      end

      it 'looks for workers under the app/workers within the Rails root' do
        located_files
        expect(Dir).to have_received(:entries).with(Pathname.new('rails_root/app/workers'))
      end

      it "only includes files that end with 'worker.rb'" do
        expect(located_files).to include('first_test_worker.rb', 'second_test_worker.rb')
      end

      it "doesn't include files that don't end with 'worker.rb'" do
        expect(located_files).not_to include("invalid.rb")
      end

      it "reverses the order of files" do
        expect(located_files).to eq(%w(second_test_worker.rb first_test_worker.rb))
      end
    end
  end
end