module ElasticQueue
  module Filters
    extend ActiveSupport::Concern

    module ClassMethods
    end

    def options_to_filters(options)
      options.map { |k, v|
        next join_options(k, v) if [:or, :and].include? k
        option_to_filter(k, v)
      }.flatten
    end

    private

    def option_to_filter(key, value)
      # return and_options(value) if key == :and
      if value.is_a? Array
        or_filter(key, value)
      elsif value.is_a? Hash
        comparison_filter(key, value)
      elsif value.nil?
        null_filter(key, value)
      else
        term_filter(key, value)
      end
    end

    def join_options(operator, options)
      j = {}
      j[operator] = options.reduce([]) { |a, option| a += options_to_filters(option) }
      j
    end

    def or_filter(term, values)
      # flatten here because ranges return arrays
      conditions = values.map { |v| option_to_filter(term, v) }.flatten
      { or: conditions }
    end

    def term_filter(term, value)
      { term: { term => value } }
    end

    # take something like follow_up: { before: 'hii', after: 'low' }
    def comparison_filter(term, value)
      value.map do |k, v|
        comparator = k.to_sym.in?([:after, :greater_than, :gt]) ? :gt : :lt
        range_filter(term, v, comparator)
      end
    end

    # like term filter but for comparison queries
    def range_filter(term, value, comparator)
      { range: { term => { comparator => value } } }
    end

    def null_filter(term, value)
      { missing: { field: term, existence: true, null_value: true } }
    end
  end
end