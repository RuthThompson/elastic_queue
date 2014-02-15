require 'elasticsearch'
require 'elastic_queue/persistence'
require 'elastic_queue/percolation'
require 'elastic_queue/query'

module ElasticQueue
  class Base
    include Persistence
    include Percolation

    def self.search_client
      hosts = OPTS['elasticsearch_hosts'].nil? ? [{ host: 'localhost', port: 9200, protocol: 'http' }] : OPTS['elasticsearch_hosts']
      Elasticsearch::Client.new hosts: hosts
    end

    def self.models(*models)
      @models = models
    end

    def self.model_names
      fail NotImplementedError, "No models defined in #{self.class}" unless defined?(@models)
      @models
    end

    def self.model_classes
      model_names.map { |s| s.to_s.camelize.constantize }
    end

    def self.index_name
      @index_name ||= to_s.underscore
    end

    def self.eager_load(includes)
      @eager_loads = includes
    end

    def self.eager_loads
      @eager_loads
    end

    def self.query(options = {})
      Query.new(self, options)
    end

    def self.filter(options)
      query.filter(options)
    end

    def self.count
      query.count
    end
  end
end