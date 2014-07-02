module ElasticQueue
  module Queueable
    extend ActiveSupport::Concern
    module ClassMethods

      def queues(*queues)
        @queues ||= queues
      end

      def queue_classes
        queues.map { |q| q.to_s.camelize.constantize }
      end

      def queue_attributes(*attributes)
        @queue_attributes ||= attributes
      end

      alias_method :analyzed_queue_attributes, :queue_attributes

      def not_analyzed_queue_attributes(*attributes)
        @not_analyzed_queue_attributes ||= attributes
      end

      # the union of analyzed and not_analyzed attributes
      def all_queue_attributes
        @queue_attributes.to_a | @not_analyzed_queue_attributes.to_a
      end

      def queue_mapping
        return if @not_analyzed_queue_attributes.blank?
        properties = {}
        @not_analyzed_queue_attributes.each do |a|
          properties[a.to_sym] = { type: :string, index: :not_analyzed }
        end
        { to_s.underscore.to_sym => { properties: properties } }
      end
    end

    def indexed_for_queue
      index = { id: id, model: self.class.to_s.underscore }
      self.class.all_queue_attributes.each do |attr|
        val = send(attr)
        val = val.to_s(:db) if val.is_a? Date
        index[attr] = val
      end
      index
    end

    def index_for_queues
      self.class.queue_classes.each { |q| q.send(:upsert_model, self) }
    end

    def remove_from_queue_indices
      self.class.queue_classes.each { |q| q.send(:remove_model, self) }
    end
  end
end