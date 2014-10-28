require 'spec_helper'
require 'sqs_worker/processor'

module SqsWorker
  describe Processor do


    subject(:processor) { described_class.new(TestWorker) }
    let(:message_body) { { foo: 'bar' } }

    let(:message_json) do
      { body: message_body, message_attributes: { correlation_id: correlation_id } }.to_json
    end

    let(:correlation_id) { 'abc123' }

    let(:message) do
      double(AWS::SQS::ReceivedMessage, body: message_json)
    end

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
            expect(worker).to receive(:perform).with(message_body)
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

        context 'with a deeply nested message body' do

          let(:message_body) { { 'foo' => 'bar', 'nested' => { 'baz' => 'boz'}, 'array' => [ { 'zip' => 'zap' } ] } }
          let(:symbolized_message_body) { message_body.deep_symbolize_keys }

          it 'passes a message for processing with symbolized keys' do
            expect(worker).to receive(:perform).with(symbolized_message_body)
            result = processor.process(message)
            expect(result[:success]).to be true
          end

        end

        context 'when the worker raises an exception' do

          let(:logger) { double('logger', error: nil) }

          before do
            SqsWorker.logger = logger
            expect(worker).to receive(:perform).with(message_body).and_raise(Exception)
          end

          after do
            SqsWorker.logger = nil
          end

          it 'logs the exception' do
            expect(logger).to receive(:error).with({
              event_name: :sqs_worker_processor_error,
              worker_class: TestWorker.name,
              error_class: Exception.name,
              exception: Exception,
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