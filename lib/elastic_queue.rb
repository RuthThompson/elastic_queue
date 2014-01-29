require 'active_support'
module ElasticQueue
  extend ActiveSupport::Autoload
  autoload :Base
  autoload :Persistence
  autoload :Percolation
  autoload :Results
end