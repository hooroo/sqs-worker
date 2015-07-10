require 'spec_helper'
require 'sqs_worker/processor'

module SqsWorker
  describe Processor do
    let(:message_json) { message_hash.to_json }
    let(:message_hash) { { body: message_body, message_attributes: { correlation_id: correlation_id } } }
    let(:message_body) { { foo: 'bar' } }

    let(:correlation_id) { 'abc123' }

    let(:message)         { instance_double(AWS::SQS::ReceivedMessage) }
    let(:parsed_message)  { OpenStruct.new(message_hash) }

    let(:worker) { instance_double(test_worker_class, perform: nil) }
    let(:logger) { double('logger', info: nil) }

    let(:test_worker_class) do
      Class.new do
        def perform(_message)
        end

        def self.config
          OpenStruct.new(queue_name: 'queue_name')
        end
      end
    end

    let(:message_parser)      { instance_double(MessageParser, parse: parsed_message) }
    let(:fake_active_record)  { double('ActiveRecord::Base', clear_active_connections!: nil) }

    subject(:processor) { described_class.new(test_worker_class, message_parser: message_parser) }

    before do
      SqsWorker.logger = logger
      stub_const('ActiveRecord::Base', fake_active_record)
    end

    describe '#process' do
      before do
        allow(test_worker_class).to receive(:new).and_return(worker)
      end

      context 'when raising an exception' do
        let(:error_handler) { Proc.new { |_| } }
        let(:config)        { OpenStruct.new(queue_name: 'queue_name', error_handlers: [error_handler]) }

        before do
          expect(worker).to receive(:perform).with(message_body).and_raise('Exception')
          allow(test_worker_class).to receive(:config).and_return(config)
        end

        it 'alerts all registered error handlers' do
          expect(logger).to receive(:error)
          expect(error_handler).to receive(:call)
          result = processor.process(message)
        end
      end

      context 'when not shutting down' do
        context 'when the worker does not raise an exception' do
          let!(:result) { processor.process(message) }

          it 'returns a successful result' do
            expect(result[:success]).to be true
          end

          it 'uses the worker class to perform an action on the message' do
            expect(worker).to have_received(:perform).with(message_body)
          end

          it 'uses the message parser to parse the message' do
            expect(message_parser).to have_received(:parse).with(message)
          end

          it 'logs the receipt of message' do
            expect(logger).to have_received(:info).with(event_name: "sqs_worker_received_message", type: test_worker_class, queue_name: test_worker_class.config.queue_name)
          end

          it 'logs the processing of message' do
            expect(logger).to have_received(:info).with(event_name: "sqs_worker_processed_message", type: test_worker_class, queue_name: test_worker_class.config.queue_name)
          end

          it 'clears active connections on active record' do
            expect(fake_active_record).to have_received(:clear_active_connections!)
          end
        end

        context 'when the worker raises an exception' do
          let(:logger) { double('logger', error: nil, info: nil) }

          before do
            SqsWorker.logger = logger
            expect(worker).to receive(:perform).with(message_body).and_raise(Exception)
          end

          it 'logs the exception' do
            expect(logger).to receive(:error).with(
                                  event_name:   :sqs_worker_processor_error,
                                  queue_name:   test_worker_class.config.queue_name,
                                  worker_class: test_worker_class.name,
                                  error_class:  Exception.name,
                                  exception:    Exception,
                                  backtrace:    Array
                              )
            processor.process(message)
          end

          it 'returns with success = false' do
            result = processor.process(message)
            expect(result[:success]).to be false
          end

          it 'clears active connections on active record' do
            expect(fake_active_record).to receive(:clear_active_connections!)
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

    after do
      SqsWorker.logger = nil
    end
  end
end

module ActiveRecord
  module Base
    def self.clear_active_connections!
    end
  end
end
