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
require 'sqs_worker'

SqsWorker.configuration = YAML.load(File.read("#{Rails.root}/config/sqs.yml"))[Rails.env]
SqsWorker.logger = Slate::Logger #  Can use any logger here

```

### Adding Workers

Adding workers for processing SQS messages is simple as creating workers in the `app/workers' folder.

Eg: A worker named `app/workers/things_to_do_worker.rb'.

```ruby
require 'sqs_worker'

class ThingsToDoWorker

  include SqsWorker::Worker

  configure queue_name: "things-to-do"

  def perform(message)
    #do the thing
  end
end
```

As long as the workers are named appropriately for ruby naming conventions and include `SqsWorker::Worker`, they will be discovered and run, picking up new messages as they are placed on the queue and run with a configurable level of parallelisation.

### Configuring the number of worker processors

Each worker can be configured with how many 'processors' are run in parallel.

```ruby
configure queue_name: "things-to-do", processors: 25
```

The default number of processors per worker is 20.  At this point there is no optimisation around the number of processors per worker for a given instance, so as worker classes are added to a given application, this number may need tweaking.  Longer term we may want to centralise the management of how many processors are assigned to each worker based on all the workers in the app and the resources available.


