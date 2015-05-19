require 'spec_helper'
require 'sqs_worker/worker_resolver'

class FirstTestWorker
  include SqsWorker::Worker
end

class SecondTestWorker
  include SqsWorker::Worker
end

class IgnoredTestWorker; end

module SqsWorker

  describe WorkerResolver do

    describe '#resolve_worker_classes' do

      before do
        allow(WorkerFileLocator).to receive(:locate).and_return(
          %w(first_test_worker.rb second_test_worker.rb ignored_test_worker.rb)
        )
      end

      it 'only includes worker classes that are actual workers' do
        expect(subject.resolve_worker_classes).to eq([FirstTestWorker, SecondTestWorker])
      end
    end
  end
end

# module SqsWorker

#   class WorkerFileLocator
#     def locate
#       Dir.entries(Rails.root.join('app', 'workers')).select do |file_name|
#         file_name.end_with?('worker.rb')
#       end.reverse
#     end
#   end

#   class WorkerResolver

#     def resolve_worker_classes

#       WorkerFileLocator.locate.inject([]) do |workers, file_name|

#         worker_class = file_name.gsub('.rb','').camelize.constantize

#         if worker_class.ancestors.include?(SqsWorker::Worker)
#           workers << worker_class
#         end

#         workers
#       end
#     end

#   end
# end