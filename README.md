# SqsWorker

Sqs worker provides a runtime for processing messages on Amazon SQS queues. It provides concurrent IO on MRI and should provide full concurrency of workers on ruby implementations that support it such as JRuby, although this has not been tested.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sqs_worker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sqs_worker

## Usage

### Configuration

Create `config/sqs.yml` with correct settings for each environment:

```yaml
production:
  use_ssl: true
  sqs_endpoint: "sqs.ap-southeast-2.amazonaws.com"
  sqs_port: 443
  access_key_id: ""
  secret_access_key: ""

staging:
  use_ssl: true
  sqs_endpoint: "sqs.ap-southeast-2.amazonaws.com"
  sqs_port: 443
  access_key_id: ""
  secret_access_key: ""

development:
  use_ssl: false
  sqs_endpoint: "localhost"
  sqs_port: 4569
  access_key_id: "fake access key"
  secret_access_key: "fake secret key"

test:
  use_ssl: false
  sqs_endpoint: "localhost"
  sqs_port: 4568
  access_key_id: "fake access key"
  secret_access_key: "fake secret key"
```

Add an initializer to your application to load configuration and set the logger.

```ruby
AWS.config(YAML.load(File.read("#{Rails.root}/config/sqs.yml"))[Rails.env])
SqsWorker.logger = Slate::Logger #  Can use any logger here

```

### Adding Workers

Adding workers for processing SQS messages is simple as creating workers in the `app/workers' folder.

Eg: A worker named `app/workers/things_to_do_worker.rb'.

```ruby
class ThingsToDoWorker

  include SqsWorker::Worker

  configure queue_name: "things-to-do"

  def perform(message)
    #do the thing
  end
end
```

As long as the workers and their file names are named using ruby naming conventions and include `SqsWorker::Worker`, they will be discovered and run. Each worker manager will fetch new messages from the queue in batches of up to 10 messages and processed with a configurable level of parallelisation.

### Configuring the number of worker processors

Each worker can be configured with how many 'processors' are run in 'parallel'.

```ruby
configure queue_name: "things-to-do", processors: 25
```

The default number of processors per worker is 10.  The number of processors is directly tied to how many messages are fetched off an SQS queue in a single request.  The formula for this is `[(num_processors / 2).to_int), 10].min`. This ensures that the the amazon sdk limit is never exceeded but decent parallelization is achieved.


At this point there is no optimisation around the number of processors per worker for a given instance, so as worker classes are added to an application, this number may need tweaking.  Longer term we may want to centralise the management of how many processors are assigned to each worker based on all the workers in the app and the resources available.

On MRI, the more IO that occurrs with fetching and processing messages, the more opportunity for parallelisation of the workers.


