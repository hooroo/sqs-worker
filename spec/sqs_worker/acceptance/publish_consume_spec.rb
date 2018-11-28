require 'spec_helper'
require 'sqs_worker/sqs'
require 'sqs_worker/sns'

describe 'Publish consumer spec', :local_only => true do

  class EventProcessor
    def perform(message); end
  end

  let(:fetcher) { SqsWorker::Fetcher.new(queue_name: test_queue, manager: manager, batch_size: 1) }
  let(:test_queue) { "test-sqs-worker-event-consumer-#{random_seed}" }
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
    allow(sqs_worker_class).to receive(:perform)
    allow(EventProcessor).to receive(:new).and_return(event_processor)
    allow(event_processor).to receive(:perform)
    sqs.create_queue(queue_name: test_queue, attributes: {}).url
    sleep(2)
    manager.prepare_to_start
  end

  after do
    queue = sqs.get_queue_by_name(queue_name: test_queue)
    queue.delete
  end

  context 'consume message' do

    let(:sample_event) do
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
    end

    context 'published via sqs_event_publisher' do

      let(:sqs_publisher) { SqsWorker::Sqs.instance.find_queue(test_queue) }

      before do
        sqs_publisher.send_message(sample_event)
        fetcher.fetch
        sleep(2)
      end

      it 'consumes the message' do
        expect(event_processor).to have_received(:perform).with(sample_event)
      end
    end

    context 'published via sns_event_publisher' do

      let(:test_topic) { "sqs-worker-test-#{random_seed}" }
      let(:sns_publisher)  { SqsWorker::Sns.instance.find_topic(test_topic) }
      let(:correlation_id) { '450cb0ae-855d-4aa9-883f-cb1e97b6c586' }

      def create_queue_policy(queue_arn, topic_arn)
        '{
          "Version":"2012-10-17",
          "Id": "' + queue_arn + '/SQSDefaultPolicy",
          "Statement":[
            {
              "Sid":"MySQSPolicy001",
              "Effect":"Allow",
              "Principal":"*",
              "Action":"sqs:SendMessage",
              "Resource":"' + queue_arn + '",
              "Condition":{
                "ArnEquals":{
                  "AWS:SourceArn":"' + topic_arn + '"
                }
              }
            }
          ]
        }'
      end

      before do
        queue = sqs.get_queue_by_name(queue_name: test_queue)
        topic = sns.create_topic(name: test_topic)
        sleep(2)
        queue_arn = queue.attributes['QueueArn']
        queue_policy = create_queue_policy(queue_arn, topic.arn)
        queue.set_attributes({
          attributes: {
            Policy: queue_policy
          }
        })
        topic.subscribe({ protocol: 'sqs', endpoint: queue_arn })
        sns_publisher.send_message(sample_event)
        fetcher.fetch
        sleep(2)
      end

      after do
        topic = sns.create_topic(name: test_topic)
        topic.delete
      end

      it 'consumes the message' do
        expect(event_processor).to have_received(:perform).with(sample_event)
      end
    end

  end
end

