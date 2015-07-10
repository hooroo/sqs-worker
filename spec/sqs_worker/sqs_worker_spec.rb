require 'spec_helper'

class MyTestWorker;end

describe SqsWorker do
  describe '.configure' do
    before do
      SqsWorker.configure do |c|
        c.worker_classes << MyTestWorker
      end
    end

    it 'allows SqsWorker to be configured' do
      expect(SqsWorker.config.worker_classes).to eq([MyTestWorker])
    end
  end
end
