require 'active_support'
require 'elasticsearch'
require 'elastic_queue/base'
require 'elastic_queue/queueable'
require 'elastic_queue/railtie.rb' if defined? Rails

module ElasticQueue
end
