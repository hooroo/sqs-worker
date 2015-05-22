require 'spec_helper'
require 'sqs_worker/queue'

module SqsWorker
  describe Queue do

    subject { described_class.new(queue, queue_name) }

    let(:queue) { double('queue', send_message: nil) }
    let(:queue_name) { 'queue_name' }
    let(:message_to_publish) { { test: "message" } }
    let(:correlation_id) { 'abc123' }
    let(:uuid) { 'xyz987' }

    let(:logger) { double('logger', info: nil) }

    before do
      allow(SqsWorker).to receive(:logger).and_return(logger)
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
      Thread.current[:correlation_id] = correlation_id

      subject.send_message(message_to_publish)
    end

    describe "#send_message" do

      describe "adding a correlation_id as a message attribute" do

        context "when the correlation_id already has been set in the current thread" do

          it "uses the specified value" do
            expect(queue).to have_received(:send_message) do |message|
              expect(JSON.parse(message)['message_attributes']['correlation_id']).to eq(correlation_id)
            end
          end
        end

        context "when the correlation_id already has not been set in the current thread" do

          let(:correlation_id) { nil }

          it "uses a generated uuid" do
            expect(queue).to have_received(:send_message) do |message|
              expect(JSON.parse(message)['message_attributes']['correlation_id']).to eq(uuid)
            end
          end
        end
      end

      context "when the message is a String" do

        let(:message_to_publish) { '{ "json" : "message" }' }

        it "converts it to json" do
          expect(queue).to have_received(:send_message) do |message|
            expect(JSON.parse(message)['body']).to eq({ 'json' => 'message' })
          end
        end
      end

      context "when the message is not a String" do

        let(:message_to_publish) { double('not a string', to_json: '{"not_a_string":"json"}') }

        it "includes the message as is" do
          expect(queue).to have_received(:send_message) do |message|
            expect(JSON.parse(message)['body']).to eq({ 'not_a_string' => 'json' })
          end
        end
      end

      it "logs the event being sent" do
        expect(logger).to have_received(:info).with(event_name: 'sqs_worker_sent_message', queue_name: queue_name)
      end
    end
  end
end