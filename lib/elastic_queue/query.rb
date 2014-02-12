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
      begin
          search = execute_query(count: false)
          search = substitute_page(search) if !count && search['hits']['hits'].length == 0 && search['hits']['total'] != 0
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest
        search = failed_search
      end
      search.with_indifferent_access
    end

    private

    def execute_query(count: false)
      search_type = count ? 'count' : 'query_then_fetch'
      @queue.search_client.search index: @queue.index_name, body: body, search_type: search_type, from: @options.from, size: @options.per_page
    end

    def substitute_page(search)
      total_hits = search['hits']['total'].to_i
      per_page = @options.per_page.to_i
      results_on_last_page = total_hits % per_page # remainder of results will be on last page
      results_on_last_page = per_page if results_on_last_page == 0 # unless the remainder is zero
      last_page = (total_hits / per_page.to_f).ceil
      last_page_start = total_hits - results_on_last_page
      @options.page = last_page
      execute_query
    end

    def failed_search
      { page: 0, hits: { hits: [], total: 0 } }
    end
  end
end