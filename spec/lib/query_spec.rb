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
end