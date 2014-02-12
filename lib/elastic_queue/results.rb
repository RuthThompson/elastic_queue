require 'will_paginate/collection'

module ElasticQueue
  class Results
    attr_reader :paginate

    delegate :empty?, :each, :total_entries, :total_pages, :current_page, to: :paginate

    def initialize(queue, search_results, query_options)
      @queue = queue
      @instantiated_queue_items = instantiate_queue_items(search_results)
      @start = query_options.page
      @per_page = query_options.per_page
      @total = search_results[:hits][:total]
      @paginate = WillPaginate::Collection.create(@start, @per_page, @total) do |pager|
        pager.replace(@instantiated_queue_items)
      end
    end

    def instantiate_queue_items(search_results)
      grouped_results, sort_order = group_sorted_results(search_results)
      records = fetch_records(grouped_results)
      sort_records(records, sort_order)
    end

    private

    # group the results by { class_name: [ids] } and save their sorted order
    def group_sorted_results(search_results)
      grouped_results = {}
      sort_order = {}
      search_results[:hits][:hits].each_with_index do |result, index|
        model = result[:_source][:model].to_sym
        model_id = result[:_source][:id]
        sort_order["#{model}_#{model_id}"] = index # save the sort order
        grouped_results[model] ||= []
        grouped_results[model] << model_id
      end
      [grouped_results, sort_order]
    end

    # take a hash of { model_name: [ids] } and return a list of records
    def fetch_records(grouped_results)
      records = []
      grouped_results.each do |model, ids|
        klass = model.to_s.camelize.constantize
        if @queue.eager_loads && @queue.eager_loads[model]
          records += klass.includes(@queue.eager_loads[model]).find_all_by_id(ids)
        else
          records += klass.find_all_by_id(ids)
        end
      end
      records
    end

    def sort_records(records, sort_order)
      records.sort do |a, b|
        sort_order["#{a.class.name.underscore}_#{a.id}"] <=> sort_order["#{b.class.name.underscore}_#{b.id}"]
      end
    end
  end
end
