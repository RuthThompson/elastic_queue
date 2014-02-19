module ElasticQueue
  class Railtie < ::Rails::Railtie
    initializer 'ElasticQueue options initializer', after: :after_initialize do
      default_config_options = { elasticsearch_hosts: [{ host: 'localhost', port: 9200, protocol: 'http' }] }.with_indifferent_access
      if defined?(Rails) && File.exists?(Rails.root.join('config', 'elastic_queue.yml').to_s)
        config_options = YAML.load_file(Rails.root.join('config', 'elastic_queue.yml').to_s)[Rails.env]
        unless config_options.nil?
          ElasticQueue::OPTIONS = default_config_options.merge(config_options.with_indifferent_access)
        end
      end
        ElasticQueue::OPTIONS = default_config_options unless defined? ElasticQueue::OPTIONS
    end
  end
end