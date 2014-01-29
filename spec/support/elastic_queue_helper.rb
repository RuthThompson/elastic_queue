module ElasticQueueHelper

  TEST_SEARCH_CLIENT = Elasticsearch::Client.new
  
  def test_search_client
    TEST_SEARCH_CLIENT
  end

  def refresh_index
    # forces the index to refresh itself so the search doesn't happen before the models are done being added to the index
    TEST_SEARCH_CLIENT.indices.refresh index: 'test_queue'
  end

  def query_all
    query = { 'query' => {'match_all' => {} } }.to_json
    TEST_SEARCH_CLIENT.search index: 'test_queue', body: query, size: 500
  end
end