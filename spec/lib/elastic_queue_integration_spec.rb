require 'spec_helper'

describe ElasticQueue do
  before :all do
    class Animal < ActiveRecord::Base
      include ElasticQueue::Queueable
      queues :test_animals_queue
      queue_attributes :dangerous, :cute, :birthdate
      not_analyzed_queue_attributes :name, :species, :description
    end

    class TestAnimalsQueue < ElasticQueue::Base
      models :animals
    end
  end

  describe 'callbacks' do
    before :each do
      create_index('test_animals_queue')
      @fluffy = Animal.create({ name: 'Fluffy' })
    end

    after :each do
      Animal.all.each(&:destroy)
      delete_index('test_animals_queue')
    end
    
    it 'adds newly created models to the queue' do
      # model was created in before block
      expect(query_all('test_animals_queue')['hits']['hits'].first['_source']['name']).to eq 'Fluffy'
    end

    it 'deletes deleted models from the queue' do
      Animal.find(@fluffy.id).destroy
      refresh_index('test_animals_queue')
      expect(query_all('test_animals_queue')['hits']['total']).to be 0
    end

    it 'updates a changed model in the queue' do
      @fluffy.update_attributes(name: 'Muffy')
      refresh_index('test_animals_queue')
      expect(query_all('test_animals_queue')['hits']['hits'].first['_source']['name']).to eq 'Muffy'
    end
  end

  describe 'sorting' do 
    before :each do
      create_index('test_animals_queue')
      Animal.create({ name: 'a', birthdate: Date.today.at_midnight - 1.year })
      Animal.create({ name: 'b', birthdate: Date.today.at_midnight - 2.years })
      Animal.create({ name: 'c', birthdate: Date.today.at_midnight - 3.year })
    end

    after :each do
      Animal.all.each(&:destroy)
      delete_index('test_animals_queue')
    end

    it 'sorts ascending and descending on one value' do
      expect(TestAnimalsQueue.query.sort(birthdate: 'asc').all.map(&:name)).to eq ['c', 'b', 'a']
      expect(TestAnimalsQueue.query.sort(birthdate: 'desc').all.map(&:name)).to eq ['a', 'b', 'c']
    end
  end
end
