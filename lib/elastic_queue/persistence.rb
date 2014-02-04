# TODO: might want to move these to an Index class
module ElasticQueue
  module Persistence
    extend ActiveSupport::Concern
    module ClassMethods

      def index_exists?
        search_client.indices.exists index: index_name
      end

      def reset_index
        delete_index if index_exists?
        create_index
      end

      def create_index
        search_client.indices.create index: index_name
        add_mappings
      end

      def delete_index
        search_client.indices.delete index: index_name
      end

      # not using it, but it is nice for debugging
      def refresh_index
        search_client.indices.refresh index: index_name
      end

      def bulk_index(batch_size = 10_000)
        create_index unless index_exists?
        model_classes.each do |klass|
          # modelclass(model).includes(associations_for_index(model)).
          index_type = klass.to_s.underscore
          klass.find_in_batches(batch_size: batch_size) do |batch|
            body = []
            batch.each do |instance|
              body << { index: { _index: index_name, _id: instance.id, _type: index_type, data: instance.indexed_for_queue } }
            end
            search_client.bulk body: body
          end
        end
      end

      def add_mappings
        model_classes.each do |klass|
          search_client.indices.put_mapping index: index_name, type: klass.to_s.underscore, body: klass.queue_mapping
        end
      end

      # TODO: move these to an instance?
      def index_model(instance)
        search_client.index index: index_name, id: instance.id, type: instance.class.to_s.underscore, body: instance.indexed_for_queue
      end

      def upsert_model(instance)
        body = { doc: instance.indexed_for_queue, doc_as_upsert: true }
        search_client.update index: index_name, id: instance.id, type: instance.class.to_s.underscore, body: body, refresh: true
      end

      def remove_model(instance)
        search_client.delete index: index_name, id: instance.id, type: instance.class.to_s.underscore
      end

    end

  end
end