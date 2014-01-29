require 'will_paginate/array'
module ElasticQueue

  class Results
    include Enumerable

    attr_reader :results

    def initialize(queue, search_results, query_options)
      @queue = queue
      @search_results = search_results
      @instantiated_queue_items = instantiate_queue_items
      @start = query_options.page
      @per_page = query_options.per_page
      @total = @search_results[:hits][:total]
      @results = WillPaginate::Collection.create(@start, @per_page, @total) { |pager| pager.replace(@instantiated_queue_items) }
    end

    def each(&block)
      @results.each(&block)
    end

    def <=>
      # TODO
    end

    def total_entries
      @total
    end

    def total_pages
      @results.total_pages
    end

    def instantiate_queue_items
      instantiated_queue_items = []
      group_sorted_results!

      @grouped_results.each do |model, ids|
        klass = model.to_s.camelize.constantize
        if @queue.eager_loads[model]
          instantiated_queue_items += klass.includes(@queue.eager_loads[model]).find_all_by_id(ids)
        else
          instantiated_queue_items += klass.find_all_by_id(ids)
        end
      end

      instantiated_queue_items.sort! do |item_a, item_b|
        @sort_order["#{item_a.class.name.underscore}_#{item_a.id}"] <=> @sort_order["#{item_b.class.name.underscore}_#{item_b.id}"]
      end
      instantiated_queue_items
    end

    private

    # group the results by { class_name: [ids] } and save their sorted order
    def group_sorted_results!
      @grouped_results = {}
      @sort_order = {}
      @search_results[:hits][:hits].each_with_index do |result, index|
        model = result[:_source][:model].to_sym
        model_id = result[:_source][:id]
        @sort_order["#{model}_#{model_id}"] = index # save the sort order
        @grouped_results[model] ||= []
        @grouped_results[model] << model_id
      end
    end

  end
end