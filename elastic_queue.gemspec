Gem::Specification.new do |s|
  s.name        = 'elastic_queue'
  s.version     = '0.0.2'
  s.date        = '2014-01-28'
  s.summary     = 'A queueing system built on top of elasticsearch.'
  s.description = 'A library for storing and filtering documents on elastic search with a queue paradigm for retrieval.'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 1.9.2'

  s.author   = 'Ruth Thompson'
  s.email    = 'ruth@flywheelnetworks.com'
  s.homepage = 'http://flywheelnetworks.com/tech'

  s.files    = ['lib/elastic_queue.rb', 'README.md']
  s.add_dependency 'activesupport'
end
