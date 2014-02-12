require 'rubygems'
require 'sqlite3'
require 'active_record'
require 'elasticsearch'
require 'spec_helper'
require_relative '../factories'

describe 'searching:' do
  
  before(:all) do
    @db = SQLite3::Database.new('test.db')
    @db.execute('
      CREATE TABLE vegetables(
      id INT PRIMARY KEY NOT NULL,
      name VARCHAR(20),
      status VARCHAR(20),
      peice_size VARCHAR(20),
      expires_at DATE)'
    )
    @db.execute('
      CREATE TABLE soups(
      id INT PRIMARY KEY NOT NULL,
      name VARCHAR(20),
      status VARCHAR(20),
      temperature INT)'
    )
    ActiveRecord::Base.establish_connection(
      :adapter => 'sqlite3',
      :database => 'test.db'
    )

    class Soup < ActiveRecord::Base
    end

    class Vegetable < ActiveRecord::Base
    end

    class TestQueue < ElasticQueue::Base
      models :soup, :vegetable
    end

    @test_queue = TestQueue
    Soup.send(:include, ElasticQueue::Queueable)
    Soup.send(:queue_attributes, :temperature)
    Soup.send(:not_analyzed_queue_attributes, :name, :status)
    Vegetable.send(:include, ElasticQueue::Queueable)
    Vegetable.send(:queue_attributes, :peice_size, :expires_at)
    Vegetable.send(:not_analyzed_queue_attributes, :name)

    @count = 10
    @count.times { FactoryGirl.create(:vegetable) }
    FactoryGirl.create(:soup)
    @test_queue.bulk_index
    refresh_index
  end

  after(:all) do
    ActiveRecord::Base.connection.close
    @db.execute('DROP TABLE vegetables')
    @db.execute('DROP TABLE soups')
    test_search_client.indices.delete index: 'test_queue'
  end

  describe ElasticQueue::Query do
    describe '#search' do
      it 'returns no results when appropriate' do
        expect(@test_queue.query.search('Wrong Name').count).to be(0)
      end

      it 'returns results when appropriate' do
        a = Vegetable.first()
        expect(@test_queue.query.search(a.name).count > 0).to be(true)
      end
    end
    
    
  end

    # it 'eager loads models when asked to' do
    #   expect(@test_queue.search('Testy Testerson', {}, { agent_fee_sales_session: :agent }).first.association(:agent).loaded?).to be(true)
    #   expect(@test_queue.search('Testy Testerson', {}, { agent_fee_sales_session: [agent: :user] }).first.agent.association(:user).loaded?).to be(true)
    # end
    # 
    # it 'does not eager load when not asked to' do
    #    expect(@test_queue.search('Testy Testerson').first.association(:agent).loaded?).to be(false)
    # end
    # 
    # it 'paginates' do
    #   expect(@test_queue.search('Testy Testerson', { per_page: 1 }).count).to be(1)
    #   first_page = @test_queue.search('Testy Testerson', { per_page: 1, page: 1 })
    #   second_page = @test_queue.search('Testy Testerson', { per_page: 1, page: 2 })
    #   expect(first_page.first.id != second_page.first.id).to be(true)
    #   expect(second_page.results.current_page.to_s).to eq('2')
    # end
    # 
    # it 'can sort results by a term' do
    #   order = @test_queue.search('Testy Testerson', { order_by: :assigned_to_id }).map(&:assigned_to)
    #   expect(order).to eq(order.sort)
    # end
    # 
    # it 'can sort in ascending and decending order' do
    #   order_desc = @test_queue.search('Testy Testerson', { order_by: :id, order: :desc }).map(&:id)
    #   order_asc = @test_queue.search('Testy Testerson', { order_by: :id, order: :asc }).map(&:id)
    #   expect(order_desc.reverse).to eq(order_asc)
    # end

  # end

#   describe '#queue' do
# 
#     describe 'with params hashes' do
# 
#       it 'returns all records if not passed any parameters' do
#         expect(@test_queue.queue().length).to be(@count*2)
#       end
# 
#       it 'returns models' do
#         expect(@test_queue.queue().first).to be_a(ActiveRecord::Base)
#       end
# 
#       describe 'with eager loading' do
# 
#         it 'eager loads when asked to' do
#           expect(@test_queue.queue({ model: :agent_fee_sales_session }, { agent_fee_sales_session: :agent }).first.association(:agent).loaded?).to be(true)
#           expect(@test_queue.queue({ model: :agent_fee_sales_session }, { agent_fee_sales_session: [agent: :user] }).first.agent.association(:user).loaded?).to be(true)
#         end
# 
#         it 'does not eager load when not asked to' do
#           expect(@test_queue.queue({ model: :agent_fee_sales_session }).first.association(:agent).loaded?).to be(false)
#         end
# 
#         it 'properly orders eager loaded models, including across models' do
#           order_with_eager_loading = @test_queue.queue({ model: [:agent_fee_sales_session, :agent], order_by: :id }, { agent_fee_sales_session: :agent, agent: :user }).map(&:id)
#           order_without_eager_loading = @test_queue.queue({ model: [:agent_fee_sales_session, :agent], order_by: :id }).map(&:id)
#           expect(order_with_eager_loading <=> order_without_eager_loading).to be(0)
#         end
# 
#       end
# 
#       describe 'with queue options' do
# 
#         it 'can recover gracefully from bad searches' do
#           expect(@test_queue.queue({ model: :agent_fee_sales_session, sort_by: 'non_attribute', non_attribute: true })).to_not raise_error
#         end
# 
#         it 'accepts either strings or symbols' do
#           with_strings = @test_queue.queue({ model: 'agent_fee_sales_session', status: 'active' }).map(&:id)
#           with_symbols = @test_queue.queue({ model: :agent_fee_sales_session, status: :active }).map(&:id)
#           expect(with_symbols).to eq(with_strings)
#         end
# 
#         it 'can search across multiple models' do
#           pending
#         end
# 
#         it 'can filter by a term' do
#           expect(@test_queue.queue({ status: :active }).map(&:status).uniq).to eq(['active'])
#           expect(@test_queue.queue({ status: :fake_status })).to eq([])
#         end
# 
#         it 'can filter by a term even if some of the models it includes don\'t have that term' do
#           pending 'verify specification for this'
#           # agent_id = AgentFeeSalesSession.first.agent_id
#           # license_state = Agent.first.license_state
#           # expect(@test_queue.queue({ agent_id: agent_id }).length).to be(1)
#           # expect(@test_queue.queue({ agent_id: agent_id, license_state: license_state }).length).to be(1)
#         end
# 
#         it 'can filter by a range' do
#           the_beginning_of_time = (Date.today - 10.years).to_time
#           agent_fee_sales_session_created_before = Time.now
#           expect(@test_queue.queue({ created_at_between: [the_beginning_of_time, Time.now] }).length).to be(@count)
#           # expect(@test_queue.queued({ created_at_between: [the_beginning_of_time, agent_fee_sales_session_created_before] }).map{ |model| model.class.to_s }.uniq).to eq(['AgentFeeSalesSession'])
#         end
# 
#         it 'can take multiple values for one term' do #or filter
#           id_1, id_2 = AgentFeeSalesSession.first(2).map(&:id)
#           expect(@test_queue.queue({ model: :agent_fee_sales_session, id: [id_1, id_2] }).length).to be(2)
#         end
# 
#         it 'can filter out a term' do #not filter
#           id_1 = AgentFeeSalesSession.first.id
#           expect(@test_queue.queue({ model: :agent_fee_sales_session, id_not: [id_1] }).length).to be(@count - 1) 
#         end
# 
#         describe 'can filter on null values (also tests #null_filter)' do
#           before(:all) do
#             @null_valued_record = FactoryGirl.create(:null_follow_up_agent_fee_sales_session)
#             @test_queue.index_models
#             refresh_index
#           end
# 
#           after(:all) do
#             @null_valued_record.delete
#             @test_queue.index_models
#             refresh_index
#           end
# 
#           it 'can filter for null values' do #null_filter
#             expect(@test_queue.queue({ model: :agent_fee_sales_session, follow_up_null: true }).length).to be(1)
#           end
# 
#           it 'can filter against null values' do #null_filter
#             expect(@test_queue.queue({ model: :agent_fee_sales_session, follow_up_null: false }).length).to be(@count)
#           end
# 
#         end
# 
#         it 'can sort results by a term' do
#           order = @test_queue.queue({ model: [:agent_fee_sales_session], order_by: :assigned_to_id }).map(&:assigned_to)
#           expect(order).to eq(order.sort)
#         end
#         
#         it 'can sort in ascending and decending order' do
#           order_desc = @test_queue.queue({ model: ['agent_fee_sales_session', 'agent'], order_by: :id, order: :desc }).map(&:id)
#           order_asc = @test_queue.queue({ model: ['agent_fee_sales_session', 'agent'], order_by: :id, order: :asc }).map(&:id)
#           expect(order_desc.reverse).to eq(order_asc)
#         end
# 
#         it 'can sort results by multiple terms' do
#           sql_order = AgentFeeSalesSession.order('assigned_to ASC, id DESC').pluck(:id)
#           elastic_queue_order = @test_queue.queue({ model: :agent_fee_sales_session, order_by: [ [:assigned_to_id, :asc], [:id, :desc] ] }).map(&:id)
#           expect(elastic_queue_order).to eq(sql_order)
#         end
# 
#       end
# 
#     end
# 
#     describe 'with chainable methods' do
# 
#       describe '#models_include' do
# 
#         it 'eager loads models' do
#           expect(@test_queue.model_includes(:agent_fee_sales_session, :agent).queue({ model: :agent_fee_sales_session }).first.association(:agent).loaded?).to be(true)
#         end
# 
#       end
# 
#       describe '#page, #per_page' do
#         it 'paginates results' do
#           page_1_ids = @test_queue.page(1).per_page(2).queue({ model: :agent_fee_sales_session }).map(&:id)
#           page_2_ids = @test_queue.page(2).per_page(2).queue({ model: :agent_fee_sales_session }).map(&:id)
#           expect(page_1_ids & page_2_ids).to eq([])
#         end
# 
#         it 'returns the last page of results if asked for too high of a page number' do
#           expect(@test_queue.page(@count*2).per_page(2).queue({ model: :agent_fee_sales_session })).to_not eq([])
#         end
# 
#       end
# 
#       describe 'dynamic methods' do
# 
#         it 'return the same results as passing an options hash' do
#           chained_dynamic_methods_search = @test_queue.model(:agent_fee_sales_session).order_by([:assigned_to_id, :asc]).order_by([:id, :desc]).queue.map(&:id)
#           options_hash_search = @test_queue.queue({ model: :agent_fee_sales_session, order_by: [ [:assigned_to_id, :asc], [:id, :desc] ] }).map(&:id)
#           expect(chained_dynamic_methods_search).to eq(options_hash_search)
#         end
# 
#         it 'isn\'t picky about how you enter array values' do
#           pending 'what do I mean by this?'
#         end
# 
#         it 'does not break method_missing' do
#           expect{ @test_queue.fake_method }.to raise_error(NoMethodError)
#         end
# 
#         it 'does not break respond_to?' do
#           expect(!@test_queue.respond_to?(:fake_method) && @test_queue.respond_to?(:to_s)).to be(true)
#         end
# 
#         it 'provides methods for every queue attribute of an indexed model' do
#           AgentFeeSalesSession.queue_attribute_method_names.each do |attr_name| # relies on elastic_queueable module
#             @test_queue.respond_to?(attr_name) || fail
#           end
#         end
# 
#         it 'provides *_before, *_after, *_not, *_null, *_greater_than and *_less_than methods for every queue attribute of an indexed model' do
#           AgentFeeSalesSession.queue_attribute_method_names.each do |attr_name| # relies on elastic_queueable module
#             ['_before', '_after', '_not', '_null', '_greater_than', '_less_than'].each do |suffix|
#               @test_queue.respond_to?("#{attr_name.to_s}#{suffix}".to_sym) || fail
#             end
#           end
#         end
# 
#       end
# 
#     end
# 
#   end
# 
#   describe '#queue_count' do
#     it 'returns the same number of records as #queue' do
#       expect(@test_queue.queue_count({})).to eq(@test_queue.queue({}).count)
#     end
# 
#     it 'works with chainable methods' do
#       pending
#     end
# 
#   end
# 
#   describe '#queue_with_data' do
#     pending
#   end
# 
# end
end