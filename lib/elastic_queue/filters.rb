module ElasticQueue
  module Filters
    extend ActiveSupport::Concern

    module ClassMethods
    end

    def options_to_filters(options)
      options.map { |k, v| option_to_filter(k, v) }.flatten
    end

    private

    def option_to_filter(key, value)
      if value.is_a? Array
        or_filter(key, value)
      elsif value.is_a? Hash
        # date?
        time_filter(key, value)
      else
        term_filter(key, value)
      end
    end

    def or_filter(term, values)
      { or: values.map { |v| term_filter(term, v) } }
    end

    def term_filter(term, value)
      { term: { term => value } }
    end

    # take something like follow_up: { before: 'hii', after: 'low' }
    def time_filter(term, value)
      value.map do |k, v|
        comparator = k.to_sym.in?([:after, :greater_than, :gt]) ? :gt : :lt
        range_filter(term, v, comparator)
      end
    end

    # like term filter but for comparison queries
    def range_filter(term, value, comparator)
      { range: { term => { comparator => value } } }
    end
  end
end