require 'elastic_queue/filters'
require 'elastic_queue/sorts'

module ElasticQueue
  class QueryOptions
    include Filters
    include Sorts

    attr_reader :filters, :sorts, :page, :per_page, :from

    def initialize(options = {})
      @defaults = {
        page: 1,
        order: 'asc',
        per_page: 30,
        page_substitution_ok: true,
      }.merge(options)
      @filters = { and: [] }.with_indifferent_access
      @sorts = []
      @per_page = @defaults[:per_page].to_i
      @page = @defaults[:page].to_i
      @from = (@page - 1) * @per_page
    end

    def add_filter(options)
      @filters[:and] += options_to_filters(options)
    end

    def add_sort(options)
      @sorts += options_to_sorts(options)
    end

    def body
      b = {}
      b[:filter] = @filters unless @filters[:and].blank?
      b[:sort] = @sorts unless @sorts.blank?
      b
    end

  end
end