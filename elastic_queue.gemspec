require './lib/elastic_queue/version'

Gem::Specification.new do |s|
  s.name        = 'elastic_queue'
  s.version     = ElasticQueue::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = 'A queueing system built on top of elasticsearch.'
  s.description = 'A library for storing and filtering documents on elastic search with a queue paradigm for retrieval.'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 1.9.2'

  s.authors   = ['Ruth Thompson', 'Rob Law']
  s.email    = %w[ ruth@flywheelnetworks.com rob@flywheelnetworks.com ]
  s.homepage = 'https://github.com/RuthThompson/elastic_queue'

  s.require_paths = %w[ lib ]
  s.files = `git ls-files`.split("\n")
  s.test_files = Dir['spec/**/*.rb']

  s.add_runtime_dependency 'activesupport', '~> 3.0'
  s.add_runtime_dependency 'elasticsearch', '~> 0.4'
  s.add_runtime_dependency 'will_paginate', '~> 3.0'
  s.add_development_dependency 'bundler', '~> 1.0'
  s.add_development_dependency 'rspec', '~> 2.6'
  s.add_development_dependency 'factory_girl', '~> 4.0'
  s.add_development_dependency 'sqlite3', '~> 1.3'
  s.add_development_dependency 'rake', '~> 10.0'
end