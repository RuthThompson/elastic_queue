require 'elasticsearch'
require 'elastic_queue/persistence'
require 'elastic_queue/percolation'
require 'elastic_queue/query'

module ElasticQueue
  class Base
    include Persistence
    include Percolation

    def self.search_client
      @search_client ||= Elasticsearch::Client.new hosts: ElasticQueue::OPTIONS[:elasticsearch_hosts]
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

    def self.index_name=(name)
      @index_name = name
    end

    def self.eager_load(includes)
      @eager_loads = includes
    end

    def self.eager_loads
      @eager_loads
    end

    def self.default_scope(proc)
      @default_scope = proc
    end

    def self.scope(name, body)
      @scopes.merge(name => body)
    end

    def self.scopes
      @scopes ||= {}
    end

    # we want to store the scope in our scopes hash
    # for use in chaining scopes
    # we also define it on the class to mimic AR scopes
    def self.scope(name, body)
      scopes.merge! name => body
      singleton_class.send(:define_method, name) do |*args|
        query.instance_exec(*args, &body)
      end
    end

    def self.query
      Query.new(self).tap do |q|
        q.instance_exec(&@default_scope) if @default_scope
      end
    end

    def self.filter(options)
      query.filter(options)
    end

    def self.count
      query.count
    end

    # instance methods
    def query
      @query ||= self.class.query
    end

  end
end