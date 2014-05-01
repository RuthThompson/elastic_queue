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

  before :each do
    create_index('test_animals_queue')
  end

  after :each
    delete_index('test_animals_queue')
  end
  
  describe 'when a new model is created, it gets saved in the queue' do
    Animal.create({ name: 'Fluffy', 
                    species: 'Cat',
                    birthdate: Date.yesterday.at_midnight,
                    dangerous: false,
                    cute: true, 
                    description: 'fluffball' })
   puts query_all('test_animals_queue')
  end
end
