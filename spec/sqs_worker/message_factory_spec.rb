require 'spec_helper'
require 'sqs_worker/message_factory'

module SqsWorker
  describe MessageFactory do

    subject(:message_factory) { described_class.new }

    let(:correlation_id) { 'abc123' }
    let(:uuid) { 'xyz987' }

    let(:message) { message_factory.message(message_to_publish) }
    let(:message_to_publish) { '{ "json" : "message" }' }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
      Thread.current[:correlation_id] = correlation_id
    end

    describe "#message" do

      describe "adding a correlation_id as a message attribute" do

        context "when the correlation_id already has been set in the current thread" do

          it "uses the specified value" do
            expect(message[:message_attributes][:correlation_id]).to eq(correlation_id)
          end
        end

        context "when the correlation_id already has not been set in the current thread" do

          let(:correlation_id) { nil }

          it "uses a generated uuid" do
            expect(message[:message_attributes][:correlation_id]).to eq(uuid)
          end
        end
      end

      context "when the message is a String" do

        it "converts it to json" do
          expect(message[:body]).to eq({ 'json' => 'message' })
        end
      end

      context "when the message is not a String" do

        let(:message_to_publish) { { 'not a string' => 'json' } }

        it "includes the message as is" do
          expect(message[:body]).to eq(message_to_publish)
        end
      end
    end
  end
end