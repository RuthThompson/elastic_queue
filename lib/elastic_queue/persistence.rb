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
        search_client.indices.create index: index_name, body: default_index_settings
        add_mappings
      end

      def delete_index
        search_client.indices.delete index: index_name
      end

      # not using it, but it is nice for debugging
      def refresh_index
        search_client.indices.refresh index: index_name
      end

      # you can pass scopes into bulk_index to be used when fetching records
      #  bulk_index(scopes: { some_model: [:scope1, :scope2], some_other_model: [:scope3] }) will fetch SomeModel.scope1.scope2 and SomeOtherModel.scope3 and index only those records.
      def bulk_index(scopes: {}, batch_size: 10_000)
        create_index unless index_exists?
        model_classes.each do |klass|
          # modelclass(model).includes(associations_for_index(model)).
          index_type = klass.to_s.underscore
          scoped_class(klass, scopes).find_in_batches(batch_size: batch_size) do |batch|
            body = []
            batch.each do |instance|
              body << { index: { _index: index_name, _id: instance.id, _type: index_type, data: instance.indexed_for_queue } }
            end
            search_client.bulk body: body
          end
        end
      end

      def scoped_class(klass, scopes)
        return klass unless scopes[klass.to_s.underscore.to_sym]
        scopes[klass.to_s.underscore.to_sym].each do |scope|
          klass = klass.send(scope)
        end
        klass
      end

      def default_index_settings
        {
          settings: {
            analysis: {
              analyzer: {
                default: {
                  type: :custom,
                  tokenizer: :whitespace,
                  filter: [:lowercase]
                }
              }
            }
          }
        }
      end

      def add_mappings
        model_classes.each do |klass|
          mapping = klass.queue_mapping
          search_client.indices.put_mapping index: index_name, type: klass.to_s.underscore, body: mapping if mapping.present?
        end
      end

      # TODO: move these to an instance?
      def index_model(instance)
        search_client.index index: index_name, id: instance.id, type: instance.class.to_s.underscore, body: instance.indexed_for_queue
      end

      def upsert_model(instance)
        body = { doc: instance.indexed_for_queue, doc_as_upsert: true }
        search_client.update index: index_name, id: instance.id, type: instance.class.to_s.underscore, body: body, refresh: true, retry_on_conflict: 20
      end

      def remove_model(instance)
        begin
          search_client.delete index: index_name, id: instance.id, type: instance.class.to_s.underscore
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          # just say you deleted it if it's not there!
        end
      end
    end
  end
end