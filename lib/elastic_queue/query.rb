require 'elastic_queue/query_options'
require 'elastic_queue/results'

module ElasticQueue
  class Query
    def initialize(queue, options = {})
      @queue = queue
      @options = QueryOptions.new(options)
    end

    def filter(options)
      @options.add_filter(options)
      self
    end

    def filters
      @options.filters
    end

    def sort(options)
      @options.add_sort(options)
      self
    end

    def sorts
      @options.sorts
    end

    def search(string)
      @options.add_search(string)
      self
    end

    def searches
      @options.search
    end

    def body
      @options.body
    end

    def percolator_body
      @options.percolator_body
    end

    def paginate(options = {})
      options.each { |k, v| @options.send("#{k}=", v) }
      all.paginate
    end

    def page=(page)
      @options.page = (page)
    end

    def all
      @results ||= Results.new(@queue, execute, @options)
    end

    # return just the ids of the records (useful when combined with SQL queries)
    def ids
      results = execute
      results[:hits][:hits].map { |h| h[:_source][:id] }
    end

    def count
      res = execute(count: true)
      res[:hits][:total].to_i
    end

    def execute(count: false)
      begin
        search = execute_query(count: false)
        search = substitute_page(search) if !count && search['hits']['hits'].length == 0 && search['hits']['total'] != 0
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest
        search = failed_search
      end
      search.with_indifferent_access
    end

    private

    # this allows you to chain scopes
    # the 2+ scopes in the chain will be called
    # on a query object and not on the base object
    def method_missing(method, *args, &block)
      if @queue.respond_to?(method)
        proc = @queue.scopes[method]
        instance_exec *args, &proc
      end
    end

    def execute_query(count: false)
      search_type = count ? 'count' : 'query_then_fetch'
      @queue.search_client.search index: @queue.index_name, body: body, search_type: search_type, from: @options.from, size: @options.per_page
    end

    def substitute_page(search)
      total_hits = search['hits']['total'].to_i
      per_page = @options.per_page
      @options.page = (total_hits / per_page.to_f).ceil
      execute_query
    end

    def failed_search
      { page: 0, hits: { hits: [], total: 0 } }
    end
  end
end