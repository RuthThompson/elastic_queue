require 'spec_helper'

describe ElasticQueue do
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

  before :each do
    TestAnimalsQueue.create_index
  end

  after :each do
    Animal.all.each(&:destroy)
    delete_index('test_animals_queue')
  end

  describe 'callbacks' do
    before :each do
      @fluffy = Animal.create({ name: 'Fluffy' })
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
    after :each do
      Animal.all.each(&:destroy)
      delete_index('test_animals_queue')
    end

    it 'sorts ascending and descending on one value' do
      Animal.create({ name: 'a', birthdate: Date.today.at_midnight - 1.year })
      Animal.create({ name: 'b', birthdate: Date.today.at_midnight - 2.years })
      Animal.create({ name: 'c', birthdate: Date.today.at_midnight - 3.years })
      expect(TestAnimalsQueue.query.sort(birthdate: 'asc').all.map(&:name)).to eq ['c', 'b', 'a']
      expect(TestAnimalsQueue.query.sort(birthdate: 'desc').all.map(&:name)).to eq ['a', 'b', 'c']
    end

    it 'sorts ascending and descending on two values' do
      Animal.create({ name: 'a', birthdate: Date.today.at_midnight - 1.year })
      Animal.create({ name: 'b', birthdate: Date.today.at_midnight - 1.years })
      Animal.create({ name: 'c', birthdate: Date.today.at_midnight - 3.years })
      expect(TestAnimalsQueue.query.sort(birthdate: 'asc').sort(name: 'asc').all.map(&:name)).to eq ['c', 'a', 'b']
      expect(TestAnimalsQueue.query.sort(birthdate: 'asc').sort(name: 'desc').all.map(&:name)).to eq ['c', 'b', 'a']
    end

    it 'doesn\'t fail to sort because of stopwords' do
      Animal.create({ name: 'and' })
      Animal.create({ name: 'or' })
      Animal.create({ name: 'if' })
      expect(TestAnimalsQueue.query.sort(name: 'asc').all.map(&:name)).to eq ['and', 'if', 'or']
    end

    it 'doesn\'t error if you try to sort on a nonexistent value' do
      expect { TestAnimalsQueue.query.sort(fake_value: 'yes').all }.to_not raise_error
    end
  end

  describe 'filtering' do
    before :each do
      Animal.create({ name: 'a', birthdate: Date.today.at_midnight - 1.year })
      Animal.create({ name: 'b', birthdate: Date.today.at_midnight - 2.years })
      Animal.create({ name: 'c', birthdate: Date.today.at_midnight - 3.years })
    end

    it 'can filter on one value' do
      expect(TestAnimalsQueue.query.filter(name: 'a').all.map(&:name)).to eq ['a']
    end

    it 'can filter by a less than or greater than a time' do
      expect(TestAnimalsQueue.query.filter(birthdate: { after: Date.today - 1.year - 1.day }).all.map(&:name)).to eq ['a']
      expect(TestAnimalsQueue.query.filter(birthdate: { before: Date.today - 2.years - 1.day }).all.map(&:name)).to eq ['c']
    end

    it 'can filter by a less than and greater than a time' do
      expect(TestAnimalsQueue.query.filter(birthdate: { after: Date.today - 2.year - 1.day, before: Date.today - 1.year - 1.day}).all.map(&:name)).to eq ['b']
    end

    it 'can filter by less than or greater than a string' do
      pending('functionality not built yet')
    end

    it 'doesn\'t error if you try to filter on an nonexistent value' do
      expect(TestAnimalsQueue.query.filter(likes_peanut_butter: true).all.map(&:name)).to eq []
    end

    it 'automatically joins multiple filter values with an OR' do
       expect(TestAnimalsQueue.query.filter(name: ['a', 'b']).all.map(&:name).sort).to eq ['a', 'b']
    end

    it 'defaults to joining multiple filter keys with an AND' do
      Animal.create({ name: 'x', species: 'dog' })
      Animal.create({ name: 'y', species: 'dog' })
      expect(TestAnimalsQueue.query.filter(name: 'x').filter(species: 'dog').all.map(&:name)).to eq ['x']
    end

    it 'can join multiple filter keys with an OR' do
      pending('doesnt work')
      Animal.create({ name: 'x', species: 'dog' })
      Animal.create({ name: 'y', species: 'cat' })
      expect(TestAnimalsQueue.query.filter(or: [{ name: 'x' }, { species: 'cat' }]).all.map(&:name).sort).to eq ['x', 'y']
    end

    it 'can join multiple filter values with multiple filter keys with an OR' do
      pending
    end
  end
end
