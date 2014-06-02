require 'spec_helper'

describe 'ElasticQueue::Filters integration' do
  before :all do
    class Animal < ActiveRecord::Base
      include ElasticQueue::Queueable
      queue_attributes :dangerous, :cute, :birthdate, :name
      not_analyzed_queue_attributes :species, :description
    end

    class TestAnimalsQueue < ElasticQueue::Base
      models :animal
    end

    TestAnimalsQueue.create_index
    
    @create_animals = -> {
      Animal.create({ name: 'a', birthdate: Date.today.at_midnight - 1.year })
      Animal.create({ name: 'b', birthdate: Date.today.at_midnight - 2.years })
      Animal.create({ name: 'c', birthdate: Date.today.at_midnight - 3.years })
    }
  end

  after :all do
    [:Animal, :TestAnimalsQueue].each do |constant|
      Object.send(:remove_const, constant)
    end
    delete_index('test_animals_queue')
  end

  describe 'ElasticQueue::Query#filter' do
    after :each do
      Animal.all.each(&:destroy)
    end

    it 'can filter on one value' do
      @create_animals.call
      expect(TestAnimalsQueue.query.filter(name: 'a').all.map(&:name)).to eq ['a']
    end

    it 'can filter by a less than or greater than a time' do
      @create_animals.call
      expect(TestAnimalsQueue.query.filter(birthdate: { after: Date.today - 1.year - 1.day }).all.map(&:name)).to eq ['a']
      expect(TestAnimalsQueue.query.filter(birthdate: { before: Date.today - 2.years - 1.day }).all.map(&:name)).to eq ['c']
    end

    it 'can filter by a less than and greater than a time' do
      @create_animals.call
      expect(TestAnimalsQueue.query.filter(birthdate: { after: Date.today - 2.year - 1.day, before: Date.today - 1.year - 1.day}).all.map(&:name)).to eq ['b']
    end

    it 'can filter by less than or greater than a string' do
      @create_animals.call
      expect(TestAnimalsQueue.query.filter(name: { after: 'a', before: 'c' }).all.map(&:name)).to eq ['b']
    end

    it 'doesn\'t error if you try to filter on an nonexistent value' do
      @create_animals.call
      expect(TestAnimalsQueue.query.filter(likes_peanut_butter: true).all.map(&:name)).to eq []
    end

    it 'filters underscored values as one word' do
      Animal.create({ name: 'pin_head' })
      Animal.create({ name: 'pin' })
      expect(TestAnimalsQueue.query.filter(name: 'pin').all.map(&:name)).to eq ['pin']
    end

    it 'automatically joins multiple filter values with an OR' do
      @create_animals.call
      expect(TestAnimalsQueue.query.filter(name: ['a', 'b']).all.map(&:name).sort).to eq ['a', 'b']
    end

    it 'defaults to joining multiple filter keys with an AND' do
      Animal.create({ name: 'x', species: 'dog' })
      Animal.create({ name: 'y', species: 'dog' })
      expect(TestAnimalsQueue.query.filter(name: 'x').filter(species: 'dog').all.map(&:name)).to eq ['x']
    end

    it 'can join multiple filter keys with an OR' do
      Animal.create({ name: 'x', species: 'dog' })
      Animal.create({ name: 'y', species: 'cat' })
      Animal.create({ name: 'z', species: 'rat' })
      expect(TestAnimalsQueue.query.filter(or: [{ name: 'x' }, { species: 'cat' }]).all.map(&:name).sort).to eq ['x', 'y']
    end

    it 'can join multiple filter values with multiple filter keys with an OR' do
      Animal.create({ name: 'x', species: 'dog' })
      Animal.create({ name: 'y', species: 'cat' })
      Animal.create({ name: 'z', species: 'chicken' })
      Animal.create({ name: 'a', species: 'chicken' })
      expect(TestAnimalsQueue.query.filter(or: [{ name: 'z' }, { species: ['cat', 'dog'] }]).all.map(&:name).sort).to eq ['x', 'y', 'z']
    end

    it 'can nest multiple ands and ors' do
      Animal.create({ name: 'rusty', species: 'dog', dangerous: false })
      Animal.create({ name: 'killer', species: 'mountain lion', dangerous: true })
      Animal.create({ name: 'cock-a-doodle-doo', species: 'chicken', dangerous: false })
      Animal.create({ name: 'old bess', species: 'cow', dangerous: true })
      Animal.create({ name: 'speedy', species: 'horse', dangerous: false })
      expect(TestAnimalsQueue.query.filter({
        # (rusty, killer, speedy) && ( rusty || lucky, killer, old bess, cock-a-doodle-doo)
        name: ['rusty', 'killer', 'speedy'], #(rusty, killer, speedy) && (
        or: [
            and: [ # rusty ||
              { species: ['dog', 'mountain lion'] },
              { dangerous: false }
            ],
            or: [ #speedy, killer, old bess, cock-a-doodle-doo )
              { species: ['horse', 'chicken'] },
              { dangerous: true }
            ]
          ]
      }).all.map(&:name).sort).to eq ['killer', 'rusty', 'speedy']
    end
  end
end