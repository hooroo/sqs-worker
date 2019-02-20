# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sqs_worker/version'

Gem::Specification.new do |spec|
  spec.name          = 'sqs_worker'
  spec.version       = SqsWorker::VERSION
  spec.authors       = ['Rob Monie']
  spec.email         = ['robmonie@gmail.com']
  spec.summary       = %q{Runtime for SQS workers}
  spec.description   = %q{Runtime for SQS workers based on celluloid}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/).reject{ |f| f =~ /\.(git|rspec|ruby-version)|fig\.yml/ }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.1.0'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'timecop', '~> 0.8.1'
  spec.add_development_dependency 'webmock', '~> 2.1.0'
  spec.add_development_dependency 'rspec-wait', '~> 0.0.8'

  spec.add_dependency 'celluloid', '~> 0.17.3'
  spec.add_dependency 'aws-sdk-sns', '~> 1.1'
  spec.add_dependency 'aws-sdk-sqs', '~> 1.3'
  spec.add_dependency 'activesupport', '>= 3.1'
end
