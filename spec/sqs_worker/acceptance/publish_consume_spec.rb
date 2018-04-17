require 'spec_helper'
require 'sqs_worker/sqs'
require 'aws-sdk-sns'

describe 'Publish consumer spec' do

  class EventProcessor
    def perform(message); end
  end

  let(:fetcher) { SqsWorker::Fetcher.new(queue_name: test_queue, manager: manager, batch_size: 1) }
  let(:test_queue) { "sqs-worker-sqs-test-#{random_seed}" }
  let(:random_seed) { SecureRandom.uuid }

  let(:manager) { SqsWorker::Manager.new(worker_class: sqs_worker_class, heartbeat_monitor: heartbeat_monitor) }

  let(:sqs_worker_class) {
    queue_name = test_queue
    Class.new do
      include SqsWorker::Worker
      configure queue_name: queue_name

      def perform(message)
        e = EventProcessor.new
        e.perform(message)
      end
    end
  }

  let(:heartbeat_monitor) { SqsWorker::Heartbeat::LogFileHeartbeatMonitor.new(logger: SqsWorker.heartbeat_logger, threshold_seconds: 60) }

  let(:sqs) { Aws::SQS::Resource.new }
  let(:sns) { Aws::SNS::Resource.new }
  let(:event_processor) { instance_double(EventProcessor) }
  let(:logger) { Logger.new(StringIO.new) }

  before do
    Aws.config.update({ region: 'ap-southeast-2' })
    SqsWorker.logger = logger
    allow(sqs_worker_class).to receive(:perform)
    allow(EventProcessor).to receive(:new).and_return(event_processor)
    allow(event_processor).to receive(:perform)
    sqs.create_queue(queue_name: test_queue, attributes: {}).url
    manager.prepare_to_start
  end

  after do
    queue = sqs.get_queue_by_name(queue_name: test_queue)
    queue.delete
  end

  context 'consume message' do
    let(:sample_event) {
      {
        id: '0ce61d60-d4cf-57a2-81a6-773ebd97e67b',
        aggregate_id: '06cd0aa7-0440-4f1d-b4a5-a27d4f87384a',
        data: {
          '1.0': {}
        },
        metadata: {
          correlation_id: '450cb0ae-855d-4aa9-883f-cb1e97b6c586',
          client_references: {
            bookings: {
              id: '06cd0aa7-0440-4f1d-b4a5-a27d4f87384a',
              change_id: 'e78fe212-f17b-49ed-bd34-cb21c24aaff1',
              reference: 'JQJP3T4RM'
            }
          },
          triggering_user: nil,
          triggering_event_id: '51105f79-2f49-5410-8f0c-93d86427489e',
          triggering_event_type: 'booking_reservation_creation_request_failed'
        },
        created_at: '2018-04-09T05:03:45.166Z',
        event_type: 'sqs_worker_acceptance_test_event'
      }
    }

    ### TODO Note: a straight SQS message payload is very different to an sqs message that has come from SNS
    # SQS worker did the following to handle this.
    #  # Get the body
    #  parsed_message = JSON.parse(message.body).deep_symbolize_keys
    #  # See if there is a Message attribute, in which case this is SNS so get the body from there
    #  parsed_message = JSON.parse(parsed_message[:Message]).deep_symbolize_keys if parsed_message[:Message]
    #
    #  Not sure this quite gets it either as the SNS message then has a `body` where as the content is
    #  encoded directly in the message.body of an SQS message

    context 'published via sqs_event_publisher' do
      let(:sqs_publisher) { SqsWorker::Sqs.instance.find_queue(test_queue) }

      before do
        sqs_publisher.send_message(sample_event)
        fetcher.fetch
        sleep(2)
      end

      after do
      end

      it 'consumes the message' do
        expect(event_processor).to have_received(:perform).with(sample_event)
      end
    end
  end
end

