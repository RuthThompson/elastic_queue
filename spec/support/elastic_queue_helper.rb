module ElasticQueueHelper
  ElasticQueue::OPTIONS = { elasticsearch_hosts: [{ host: 'localhost', port: 9200, protocol: 'http' }] }

  TEST_SEARCH_CLIENT = Elasticsearch::Client.new

  def test_search_client
    TEST_SEARCH_CLIENT
  end

  def create_index(index_name)
    if test_search_client.indices.exists index: index_name
      delete_index(index_name)
    end
    test_search_client.indices.create index: index_name
  end

  def delete_index(index_name)
    if test_search_client.indices.exists index: index_name
      test_search_client.indices.delete index: index_name
    end
  end

  def refresh_index(index_name)
    # forces the index to refresh itself so the search doesn't happen before the models are done being added to the index
    test_search_client.indices.refresh index: index_name
  end

  def query_all(index_name)
    query = { 'query' => {'match_all' => {} } }.to_json
    test_search_client.search index: index_name, body: query, size: 500
  end
end