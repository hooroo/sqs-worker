require 'spec_helper'
require 'sqs_worker/processor'

module SqsWorker
  describe Processor do


    subject(:processor) { described_class.new(TestWorker) }
    let(:message) { { foo: 'bar' } }
    let(:worker) { double(TestWorker) }
    let(:logger) { double('logger', info: nil) }


    before do
      SqsWorker.logger = logger
    end

    after do
      SqsWorker.logger = nil
    end


    describe '#process' do

      before do
        allow(TestWorker).to receive(:new).and_return(worker)
      end

      context 'when not shutting down' do

        context 'when the worker does not raise an exception' do

          before do
            expect(worker).to receive(:perform).with(message)
          end

          it 'succesfully processes the worker' do
            result = processor.process(message)
            expect(result[:success]).to be true
          end

          it 'logs the processing of message' do
            expect(logger).to receive(:info).with(event_name: "sqs_worker_processed_message", type: TestWorker)
            processor.process(message)
          end

          it 'clears active connections on active record' do
            expect(::ActiveRecord::Base).to receive(:clear_active_connections!)
            result = processor.process(message)
          end

        end

        context 'when the worker raises an exception' do

          let(:logger) { double('logger', error: nil) }

          before do
            SqsWorker.logger = logger
            expect(worker).to receive(:perform).with(message).and_raise(Exception)
          end

          after do
            SqsWorker.logger = nil
          end

          it 'logs the exception' do
            expect(logger).to receive(:error).with({
              event_name: :sqs_worker_error,
              worker_class: TestWorker.name,
              error_class: Exception.name,
              backtrace: Array
            })
            processor.process(message)
          end

          it 'returns with success = false' do
            result = processor.process(message)
            expect(result[:success]).to be false
          end

          it 'clears active connections on active record' do
            expect(::ActiveRecord::Base).to receive(:clear_active_connections!)
            result = processor.process(message)
          end

        end
      end

      context 'when shutting down' do

        before do
          processor.publish('SIGTERM')
        end

        it 'does not process the message' do
          expect(worker).to_not receive(:perform)
          processor.process(message)
        end

        it 'returns with success = false' do
          result = processor.process(message)
          expect(result[:success]).to be false
        end

      end

    end

    it 'subscribes for shutdown' do
      processor.publish('SIGTERM')
      expect(processor.shutting_down?).to be true
    end

  end
end

class TestWorker
  def perform(message)

  end
end

module ActiveRecord
  module Base
    def self.clear_active_connections!

    end
  end
end