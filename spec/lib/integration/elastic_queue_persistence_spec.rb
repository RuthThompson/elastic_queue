require 'spec_helper'

describe ElasticQueue::Persistence do
  before :all do
    class Animal < ActiveRecord::Base
      include ElasticQueue::Queueable
      queues :test_animals_queue
      queue_attributes :dangerous, :cute, :birthdate
      not_analyzed_queue_attributes :species, :description, :name
    end
  
    class TestAnimalsQueue < ElasticQueue::Base
      models :animal
    end
  end

  after :each do
    delete_index('test_animals_queue')
  end

  describe '#index_exists?' do
    it 'gives false when its index doesnt exist' do
      delete_index('test_animals_queue')
      expect(TestAnimalsQueue.index_exists?).to be false
    end

    it 'gives true when its index exists' do
      create_index('test_animals_queue')
      expect(TestAnimalsQueue.index_exists?).to be true
    end
  end

  describe '#reset_index' do
    pending
  end

  describe '#create_index' do
    it 'sets the default analyzer to simple' do
      TestAnimalsQueue.create_index
      expect(`curl -XGET 'localhost:9200/test_animals_queue/_analyze?' -d 'AND OR'`)
      .to eq('{"tokens":[{"token":"and","start_offset":0,"end_offset":3,"type":"word","position":1},{"token":"or","start_offset":4,"end_offset":6,"type":"word","position":2}]}')
    end
  end

  describe '#delete_index' do
    pending
  end
  
  describe '#bulk_index' do
    pending
  end

  describe '#add_mappings' do
    pending
  end

  describe '#index_model' do
    pending
  end

  describe '#upsert_model' do
    pending
  end

  describe '#remove_model' do
    pending
  end
end