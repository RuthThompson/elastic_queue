module ElasticQueue
  class Railtie < ::Rails::Railtie
    initializer 'ElasticQueue options initializer', after: :after_initialize do
      elastic_queue_default_options = { elasticsearch_hosts: [{ host: 'localhost', port: 9200, protocol: 'http' }] }.with_indifferent_access
      if defined?(Rails) && File.exists?("#{Rails.root.to_s}/config/elastic_queue.yml")
        ElasticQueue::OPTIONS = elastic_queue_default_options.merge(YAML.load_file("#{Rails.root.to_s}/config/elastic_queue.yml")[Rails.env].with_indifferent_access)
      else
        ElasticQueue::OPTIONS = elastic_queue_default_options
      end
    end
  end
end