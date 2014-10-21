# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sqs_worker/version'

Gem::Specification.new do |spec|
  spec.name          = "sqs-worker"
  spec.version       = SqsWorker::VERSION
  spec.authors       = ["Rob Monie"]
  spec.email         = ["robmonie@gmail.com"]
  spec.summary       = %q{Runtime for SQS workers}
  spec.description   = %q{Runtime for SQS workers based on celluloid}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec', '~> 3.1.0'
  spec.add_development_dependency 'pry'

  spec.add_dependency "celluloid", "~> 0.16.0"
  spec.add_dependency 'aws-sdk', '~> 1.54.0'

end
