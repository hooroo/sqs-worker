require 'spec_helper'
require 'sqs_worker/worker_file_locator'

module SqsWorker

  class Rails;end # we shouldn't refer to Rails root as the rest of SQS worker is not rails specific

  describe WorkerFileLocator do

    describe '.locate' do

      let(:located_files) { described_class.locate }

      before do
        allow(Dir).to receive(:entries).and_return(
          %w(first_test_worker.rb second_test_worker.rb invalid.rb)
        )
        allow(Dir).to receive(:exists?).with('worker_root').and_return(directory_exists)
        allow(SqsWorker.config).to receive(:worker_root).and_return('worker_root')
      end

      context "when the worker root isn't an existing directory" do
        let(:directory_exists) { false }

        it 'finds no files' do
          expect(located_files).to be_empty
        end
      end

      context "when the worker root is an existing directory" do

        let(:directory_exists) { true }

        it 'looks for workers under the configured worker root' do
          located_files
          expect(Dir).to have_received(:entries).with('worker_root')
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
end