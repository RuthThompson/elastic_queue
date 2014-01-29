module ElasticQueue
  module Queueable
    extend ActiveSupport::Concern

    included do
      after_commit :index_for_queues, if: :persisted?
      after_touch :index_for_queues, if: :persisted?
      before_destroy :remove_from_queue_indices
    end

    module ClassMethods

      def queues(*queues)
        @queues = queues
      end

      def queue_names
        raise NotImplementedError, "No queues defined in #{self}" unless defined?(@queues)
        @queues
      end

      def queue_classes
        queue_names.map { |q| q.to_s.camelize.constantize }
      end

      def queue_attributes(*attributes)
        @queue_attributes = attributes
      end

      def queue_attribute_method_names
        raise NotImplementedError, "No queue attributes defined in #{self}" unless defined?(@queue_attributes)
        @queue_attributes
      end

    end

    def indexed_for_queue
      index = { id: id, model: self.class.to_s.underscore }
      self.class.queue_attribute_method_names.each do |attr|
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