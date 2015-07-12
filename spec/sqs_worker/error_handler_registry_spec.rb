require 'spec_helper'
require 'sqs_worker/error_handler_registry'

module SqsWorker
  describe ErrorHandlerRegistry do
    let(:handler) { double('Error Handler') }

    subject(:registry) { described_class.clone }

    describe '.empty?' do
      context 'when a handler has been added' do
        it 'returns true' do
          expect(subject).to be_empty
        end
      end

      context 'when a handler has been added' do
        before do
          registry.register(handler)
        end

        it 'returns false' do
          expect(subject).to_not be_empty
        end
      end
    end

    describe '.register' do
      it 'adds the given handler' do
        registry.register(handler)
        expect(registry.handlers.first).to eq(handler)
      end

      context 'when there are more than one' do
        let(:other_handler) { double('Other Error Handler') }
        let(:handlers)      { [handler, other_handler] }

        it 'adds the handlers' do
          registry.register(handlers)
          expect(registry.handlers).to include(handler, other_handler)
        end
      end

      context 'when the handler has already been added' do
        before do
          registry.register(handler)
        end

        it 'does not add it again' do
          registry.register(handler)
          expect(registry.handlers.to_a).to eq([handler])
        end
      end
    end
  end
end
