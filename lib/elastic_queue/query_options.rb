require 'elastic_queue/filters'
require 'elastic_queue/sorts'

module ElasticQueue
  class QueryOptions
    include Filters
    include Sorts

    attr_reader :filters, :sorts
    attr_accessor :per_page

    def initialize(options = {})
      @options = { per_page: 30, page: 1 }.merge(options)
      @filters = { and: [] }.with_indifferent_access
      @sorts = []
      self.per_page = @options[:per_page]
      self.page = @options[:page]
    end

    def add_filter(options)
      @filters[:and] += options_to_filters(options)
    end

    def add_sort(options)
      @sorts += options_to_sorts(options)
    end

    def from
      (page - 1) * per_page
    end

    def page=(num)
      @page = num.to_i unless num.blank?
    end

    def page
      @page
    end

    def body
      b = {}
      b[:filter] = @filters unless @filters[:and].blank?
      b[:sort] = @sorts unless @sorts.blank?
      b
    end

    def percolator_body
      b = {}
      b[:filter] = @filters unless @filters[:and].blank?
      { 'query' => { 'constant_score' => b } }
    end

  end
end