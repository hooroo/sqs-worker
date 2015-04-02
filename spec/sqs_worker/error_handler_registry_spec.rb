require 'spec_helper'
require 'sqs_worker/error_handler_registry'

module SqsWorker
  describe ErrorHandlerRegistry do
    subject(:registry) { described_class }
    let(:handler) { double }

    before do
      registry.register(handler)
    end

    describe '#register' do
      it 'added a new error handler to the registry' do
        expect(registry.error_handlers.member?(handler)).to be(true)
      end

      it 'only once' do
        registry.register(handler)
        expect(registry.error_handlers.count).to be(1)
      end
    end

  end
end
