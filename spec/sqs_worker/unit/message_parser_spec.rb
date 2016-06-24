require 'spec_helper'
require 'sqs_worker/message_parser'

module SqsWorker
  describe MessageParser do

    subject(:message_parser) { described_class.new }

    describe '#parse' do

      let(:message) { instance_double(AWS::SQS::ReceivedMessage, body: json_message) }

      let(:message_body) { { 'foo' => 'bar', 'nested' => { 'baz' => 'boz'}, 'array' => [ { 'zip' => 'zap' } ] } }
      let(:message_attributes) { { 'correlation_id' => 'some_id' } }

      let(:parsed_message) { message_parser.parse(message) }

      context 'with a deeply nested message body' do

        let(:json_message) { { 'body' => message_body, 'message_attributes' => message_attributes }.to_json }

        it 'returns a message with a parsed body with symbolized keys' do
          expect(parsed_message.body).to eq({ foo: 'bar', nested: { baz: 'boz'}, array: [{ zip: 'zap' }]})
        end

        it 'returns a message with a parsed message attributes with symbolized keys' do
          expect(parsed_message.message_attributes).to eq({ correlation_id: 'some_id' })
        end
      end

      context 'with a body which has been been wrapped by SNS' do

        let(:json_message) { { 'Message' => { 'body' => message_body, 'message_attributes' => message_attributes }.to_json }.to_json }

        it 'returns a message with a parsed body with symbolized keys' do
          expect(parsed_message.body).to eq({ foo: 'bar', nested: { baz: 'boz'}, array: [{ zip: 'zap' }]})
        end

        it 'returns a message with a parsed message attributes with symbolized keys' do
          expect(parsed_message.message_attributes).to eq({ correlation_id: 'some_id' })
        end
      end

      context 'with the body missing' do

        let(:json_message) { { 'message_attributes' => message_attributes }.to_json }

        it 'raises an error' do
          expect { parsed_message }.to raise_error(SqsWorker::Errors::MessageFormat)
        end
      end

      context 'with the message attributes missing' do

        let(:json_message) { { 'body' => message_body }.to_json }

        it 'raises an error' do
          expect { parsed_message }.to raise_error(SqsWorker::Errors::MessageFormat)
        end
      end

      context 'with unparseable JSON' do

        let(:json_message) { 'you cannot parse me!' }

        it 'raises an error' do
          expect { parsed_message }.to raise_error(SqsWorker::Errors::MessageFormat)
        end
      end
    end
  end
end
