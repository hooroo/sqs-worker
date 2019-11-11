require 'spec_helper'
require 'sqs_worker/message_factory'

module SqsWorker
  describe MessageFactory do

    subject(:message_factory) { described_class.new }
  
    let(:correlation_id) { 'abc123' }
    let(:event_type) { 'booking_blocked' } 
    let(:uuid) { 'xyz987' }

    let(:message) { message_factory.message(message_to_publish) }
    let(:message_to_publish) { double(event_type: event_type) }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
      Thread.current[:correlation_id] = correlation_id
    end

    describe '#message' do

      describe 'adding a correlation_id as a message attribute' do

        context 'when the correlation_id already has been set in the current thread' do

          it 'uses the specified value' do
            expect(message[:message_attributes][:correlation_id]).to eq(correlation_id)
          end
        end

        context 'when the correlation_id already has not been set in the current thread' do

          let(:correlation_id) { nil }

          it 'uses a generated uuid' do
            expect(message[:message_attributes][:correlation_id]).to eq(uuid)
          end
        end
      end

      describe 'adding the event_type as a message attribute' do

        context 'when the event_type exists' do

          it 'uses the specified event type' do
            expect(message[:message_attributes][:event_type]).to eq(event_type)
          end
        end

        context 'when the event_type does not exist' do

          let(:event_type) { nil }

          it 'sets the event_type as unknown' do
            expect(message[:message_attributes][:event_type]).to eq('unknown')
          end
        end
      end

      context 'when the message is a String' do

        let(:message_to_publish) { '{ "json" : "message" }' }

        it 'converts it to json' do
          expect(message[:body]).to eq({ 'json' => 'message' })
        end
      end

      context 'when the message is not a String' do

        let(:message_to_publish) { { 'not a string' => 'json' } }

        it 'includes the message as is' do
          expect(message[:body]).to eq(message_to_publish)
        end
      end
    end
  end
end
