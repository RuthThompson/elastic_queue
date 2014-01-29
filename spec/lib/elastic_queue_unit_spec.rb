require 'elasticsearch'
require 'spec_helper'
require_relative '../../lib/elastic_queue'

describe ElasticQueue do

  before(:all) do
    class TestQueue < ElasticQueue::Base
      models :agent_fee_sales_session, :agent
    end
    @test_queue = TestQueue
    AgentFeeSalesSession.send(:include, ElasticQueueable)
    AgentFeeSalesSession.send(:queue_attributes, :agent_id, :status, :assigned_to_id, :assigned_at, :expires_at, :follow_up, :priority, :hot, :created_at, :updated_at)
    Agent.send(:include, ElasticQueueable)
    Agent.send(:queue_attributes, :status, :license_state)
  end

  describe 'naming:' do

    describe '#index_name' do
      it 'returns the correct index name' do
        expect('test_queue') == @test_queue.index_name
      end
    end

    describe '#model_names' do #Randomized with seed 41805 will cause this to fail 'cause we already sent models to TestQueue in the next block
      it 'complains if the user hasn\'t set any models' do
        class TestQueue < ElasticQueue::Base
        end
        expect{TestQueue2.model_names}.to raise_error(NotImplementedError)
      end

      it 'returns the correct model names' do
        expect(@test_queue.model_names).to eq([:agent_fee_sales_session, :agent])
      end
    end

  end

  describe 'index management' do

    before(:each) do
      @model = FactoryGirl.create(:agent_fee_sales_session)
    end

    after(:each) do
      if test_search_client.indices.exists index: 'test_queue'
        test_search_client.indices.delete index: 'test_queue'
      end
    end

    describe '#index_exists?' do

      it 'returns false for a non-existing index' do
        class TestQueue < ElasticQueue::Base
        end
        expect(TestQueue3.index_exists?).to eq(false)
      end

      it 'returns true for an existing index' do
        test_search_client.indices.create index: 'test_queue'
        expect(@test_queue.index_exists?).to eq(true)
      end

    end

    describe '#initialize_index' do
      pending
    end

    describe '#create_or_recreate_index' do
      pending
    end

    describe '#create_index' do
      pending
    end

    describe '#delete_index' do
      pending
    end

    describe '#index_models' do

      it 'should create the index' do
        @test_queue.index_models
        expect(test_search_client.indices.exists index: 'test_queue').to eq(true)
      end

      it 'should index the models' do
        @test_queue.index_models
        refresh_index
        expect((query_all)['hits']['hits'].first['_source']['model']).to eq('agent_fee_sales_session')
      end

      it 'should overwrite the old index if it already exists' do
        pending 'is this really testing what I think it is?'
        @test_queue.index_models
        refresh_index
        first_id = query_all['hits']['hits'].last['_source']['id']
        @model.delete
        @model2 = FactoryGirl.create(:agent_fee_sales_session)
        @test_queue.index_models
        refresh_index
        second_id = query_all['hits']['hits'].last['_source']['id']
        expect(first_id == second_id).to eq(false)
      end

    end

  end

  describe 'record management' do

    before(:each) do
      @count = 10
      @count.times{ FactoryGirl.create(:agent_fee_sales_session) }
      @test_queue.index_models
      refresh_index
      @model = FactoryGirl.create(:agent_fee_sales_session)
    end

    after(:each) do
      AgentFeeSalesSession.all.each(&:delete)
      test_search_client.indices.delete index: 'test_queue'
    end

    describe '#index_model' do

      it 'should add the model to the index' do
        before_index = query_all['hits']['hits'].map{ |hit| hit['_source']['id'].to_i }
        expect(before_index.include?(@model.id)).to be(false) # ensure the test is doing what we expect
        @test_queue.index_model(@model)
        refresh_index
        after_index = query_all['hits']['hits'].map{ |hit| hit['_source']['id'].to_i }
        expect(after_index.include?(@model.id)).to be(true)
      end

    end

    describe '#upsert_model' do
      it 'should update an already existing record' do
        now = Time.now.to_s
        record = AgentFeeSalesSession.first
        record.follow_up = now
        record.save
        record.reload
        @test_queue.upsert_model(record)
        refresh_index
        query = { 'filter' => { 'and' => [{ 'term' => { 'model' => 'agent_fee_sales_session' } }, { 'term' => { 'id' => record.id.to_s } }] } }
        query_index = test_search_client.search index: 'test_queue', body: query.to_json
        expect(Time.parse(query_index['hits']['hits'].first['_source']['follow_up']).to_s).to eq(record.follow_up.to_s)
      end

      it 'should insert a non-existing record' do
        query = { 'filter' => { 'term' => { 'model' => 'agent_fee_sales_session' } } }
        before_upsert = test_search_client.search index: 'test_queue', size: @count * 2, body: query.to_json
        @test_queue.upsert_model(@model)
        refresh_index
        after_upsert = test_search_client.search index: 'test_queue', size: @count * 2, body: query.to_json
        expect(before_upsert['hits']['total'] + 1).to be(after_upsert['hits']['total'])
        expect(after_upsert['hits']['hits'].map{ |hit| hit['_source']['id'].to_i }.include?(@model.id)).to eq(true)
      end
    end

    describe '#remove_model' do
      it 'should remove a given model from the index' do
        to_remove = AgentFeeSalesSession.first
        @test_queue.remove_model(to_remove)
        refresh_index
        query = { 'filter' => { 'term' => { 'model' => 'agent_fee_sales_session' } } }
        after_removal = test_search_client.search index: 'test_queue', size: @count, body: query.to_json
        expect(after_removal['hits']['hits'].map{ |hit| hit['_source']['id'].to_i }.include?(to_remove.id)).to eq(false)
      end
    end

  end

  describe 'percolation' do

    before(:each) do
      @test_queue.index_models
      refresh_index
      @model = FactoryGirl.create(:agent_fee_sales_session)
    end

    after(:each) do
      AgentFeeSalesSession.all.each(&:delete)
      test_search_client.indices.delete index: 'test_queue'
    end

    describe '#register_percolator_query' do
      pending
    end

    describe '#reverse_search' do
      pending
    end

    describe '#unregister_percolator_query' do
      pending
    end

    describe '#list_percolator_queries' do
      pending
    end

    describe '#model_in_queue?' do
      it 'should return true for a model that would be in the queue' do
        expect(@test_queue.model_in_queue?(@model, { model: :agent_fee_sales_session })).to be(true)
      end

      it 'should return false for a model that would not be in the queue' do
        expect(@test_queue.model_in_queue?(@model, { model: :agent })).to be(false)
      end
    end

  end

end