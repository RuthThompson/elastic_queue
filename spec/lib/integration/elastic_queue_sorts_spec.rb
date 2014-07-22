require 'spec_helper'

describe 'ElasticQueue::Sorts integration' do
  before :all do
    class Animal < ActiveRecord::Base
      include ElasticQueue::Queueable
      queues :test_animals_queue
      queue_attributes :dangerous, :cute, :birthdate
      not_analyzed_queue_attributes :species, :description, :name
      after_save :index_for_queues
      before_destroy :remove_from_queue_indices
    end

    class Plant < ActiveRecord::Base
      include ElasticQueue::Queueable
      queues :test_animals_queue
      queue_attributes :edible, :poisonous
      not_analyzed_queue_attributes :species, :description, :name
      after_save :index_for_queues
      before_destroy :remove_from_queue_indices
    end

    class TestAnimalsQueue < ElasticQueue::Base
      models :animal, :plant
    end

    TestAnimalsQueue.create_index
  end

  after :all do
    Animal.all.each(&:destroy)
    Plant.all.each(&:destroy)

    [:Animal, :Plant, :TestAnimalsQueue].each do |constant|
      Object.send(:remove_const, constant)
    end
    delete_index('test_animals_queue')
  end

  describe 'ElasticQueue::Query#sort' do
    after :each do
      Animal.all.each(&:destroy)
      Plant.all.each(&:destroy)
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

    it 'can sort across indices and pages' do
      Plant.create({name: 'shademaster 2000', species: 'sequoiadendron giganteum'})
      start_time = Time.now
      time = Time.now
      expect = []
      ('a'..'z').to_a.each do |l|
        10.times do
          expect << l
          Animal.create({ name: l, birthdate: time, dangerous: false, species: 'felis catus' })
          time += 1.second
        end
      end
      expect(TestAnimalsQueue.query.filter(birthdate: [nil, { before: time } ]).filter(species: 'felis catus').sort(birthdate: :asc).all.map(&:name)).to eq expect
    end

    it 'doesn\'t fail to sort because of stopwords' do
      Animal.create({ name: 'and' })
      Animal.create({ name: 'or' })
      Animal.create({ name: 'if' })
      expect(TestAnimalsQueue.query.sort(name: 'asc').all.map(&:name)).to eq ['and', 'if', 'or']
    end

    it 'doesn\'t error if you try to sort on a nonexistent value' do
      Animal.create({ name: 'a'})
      expect { TestAnimalsQueue.query.sort(fake_value: 'yes').all }.to_not raise_error
    end
  end
end
