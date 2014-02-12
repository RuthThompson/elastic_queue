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

    def count
      res = execute(count: true)
      res[:hits][:total].to_i
    end

    def execute(count: false)
      search_type = count ? 'count' : 'query_then_fetch'
      begin
        search = @queue.search_client.search index: @queue.index_name, body: body, search_type: search_type, from: @options.from, size: @options.per_page
        # search[:page] = @page
        # search = substitute_page(opts, search) if !count && opts[:page_substitution_ok] && search['hits']['hits'].length == 0 && search['hits']['total'] != 0
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest
        search = failed_search
      end
      search.with_indifferent_access
    end

    def failed_search
      { page: 0, hits: { hits: [], total: 0 } }
    end
  end
end