module ElasticQueue
  module Percolation
    extend ActiveSupport::Concern

    module ClassMethods

    #   def percolator_queries
    #     queries = {}
    #     query = { 'query' => {'match_all' => {}} }
    #     search = search_client.search index: '_percolator', body: query.to_json, size: 1000
    #     search['hits']['hits'].each  { |hit|           queries[hit['_id']] = hit['_source'] }
    #     queries
    #   end

    end

    def in_queue?(model)
      return false unless self.class.model_names.include?(model.class.to_s.underscore.to_sym)
      search_id = SecureRandom.uuid
      body = { 'doc' => model.indexed_for_queue, 'query' => {'term' => {'_id' => search_id}} }
      self.class.search_client.index index: '_percolator', type: 'dynamic_percolator', id: search_id, body: @query.percolator_body, refresh: true
      search = self.class.search_client.percolate index: 'dynamic_percolator', body: body
      self.class.search_client.delete index: '_percolator', type: 'dynamic_percolator', id: search_id
      search['matches'].length == 1
    end

    # def translate_opts_to_query_for_percolator(opts)
    #   opts = opts.symbolize_keys.select{ |key, value| non_attribute_opts.exclude?(key)}
    #   { 'query' => { 'constant_score' => translate_opts_to_query!(opts, false) } }.to_json
    # end

    # def reverse_search(instance)
    #   body = { 'doc' => instance.indexed_for_queue }
    #   search_client.percolate index: index_name, body: body.to_json
    # end

    # def register_percolator_query(name, opts)
    #   search_client.index index: '_percolator', type: index_name, id: name, body: translate_opts_to_query_for_percolator(opts)
    # end

    # def unregister_percolator_query(name)
    #   SEARCH_CLIENT.delete index: '_percolator', type: index_name, id: name
    # end

  end
end