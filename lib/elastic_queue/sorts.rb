module ElasticQueue
  module Sorts
    extend ActiveSupport::Concern

    def options_to_sorts(options)
      options.map { |k, v| option_to_sort(k, v) }
    end

    private

    def option_to_sort(key, value)
      single_sort(key, value)
    end

    def single_sort(order_by, order)
      { order_by => { order: order, ignore_unmapped: true } }
    end
  end
end