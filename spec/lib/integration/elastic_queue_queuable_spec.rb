require 'spec_helper'

describe 'ElasticQueue::Queueable integration' do
  before :all do
    class Animal < ActiveRecord::Base
      include ElasticQueue::Queueable
      queue_attributes :dangerous, :cute, :birthdate
      not_analyzed_queue_attributes :species, :description, :name
    end

    class TestAnimalsQueue < ElasticQueue::Base
      models :animal
    end
  end

  after :all do
    [:Animal, :TestAnimalsQueue].each do |constant|
      Object.send(:remove_const, constant)
    end
  end

  describe 'callbacks' do
    before :each do
      TestAnimalsQueue.create_index
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

  describe '#add_queue' do
    after :each do
      [:SomeModel, :SomeOtherModel, :SomeQueue, :SomeOtherQueue].each do |constant|
        Object.send(:remove_const, constant) if Object.constants.include? constant
      end
    end
    it 'adds a queue to its list of queues' do
      class SomeModel < ActiveRecord::Base
        include ElasticQueue::Queueable
      end
      class SomeQueue < ElasticQueue::Base
      end
      SomeModel.add_queue(:some_queue)
      expect(SomeModel.queues.sort).to eq [:some_queue]
    end

    it 'only adds each queue once' do
      class SomeOtherModel < ActiveRecord::Base
        include ElasticQueue::Queueable
      end
      class SomeQueue < ElasticQueue::Base
      end
      class SomeOtherQueue < ElasticQueue::Base
      end
      SomeOtherModel.add_queue(:some_queue)
      SomeOtherModel.add_queue(:some_other_queue)
      SomeOtherModel.add_queue(:some_queue)
      expect(SomeOtherModel.queues.sort).to eq [:some_other_queue, :some_queue]
    end
  end
end
