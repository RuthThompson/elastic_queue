require 'spec_helper'

describe ElasticQueue::Query do
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
  
    TestAnimalsQueue.create_index
  end

  after :all do
    delete_index('test_animals_queue')
  end

  describe 'getting results' do
    before :all do
      animals = []
      (0...55).each { |name| animals << { name: name } }
      Animal.create(animals)
    end
  
    after :all do
      Animal.all.each(&:destroy)
    end
    
    describe '#paginate' do
      it 'runs the query and returns a WillPaginate::Collection' do
        expect(TestAnimalsQueue.query.paginate).to be_a(WillPaginate::Collection)
      end

      it 'has pagination defaults of { page: 1, per_page: 30 }' do
        expect(TestAnimalsQueue.query.paginate.length).to eq 30
        expect(TestAnimalsQueue.query.paginate.current_page).to eq 1
      end

      it 'the returned collection knows how many results there are total' do
        expect(TestAnimalsQueue.query.paginate.total_entries).to eq 55
      end

      it 'can take per_page as an option' do
        expect(TestAnimalsQueue.query.paginate({ per_page: 2 }).length).to eq 2
      end

      it 'can take page as an option' do
        first_result_on_page_1 = TestAnimalsQueue.query.paginate({ page: 1 }).first.id
        first_result_on_page_2 = TestAnimalsQueue.query.paginate({ page: 2 }).first.id
        expect(first_result_on_page_1).to_not eq first_result_on_page_2
      end

      it 'can take both page and per_page as options at the same time' do
         expect(TestAnimalsQueue.query.paginate({ page: 2, per_page: 2 }).length).to eq 2
         expect(TestAnimalsQueue.query.paginate({ page: 2, per_page: 2 }).current_page).to eq 2
      end
    end

    describe '#all' do
      it 'returns an array' do
        expect(TestAnimalsQueue.query.all).to be_a(Array)
      end

      it 'returns all results' do
        expect(TestAnimalsQueue.query.all.length).to be 55
      end

      it 'query no longer takes pagination options (except via paginate) but even if it did, #all wouldnt use them' do
        pending('is this really necessary?')
      end
    end

    describe '#count' do
      it 'returns the count of the number of results' do
       expect(TestAnimalsQueue.query.all.count).to be 55
      end

      it 'does not make elasticsearch fetch all the records' do
        pending
      end

      it 'if someone is being stupid and using the paginate option with count it does not affect the result' do
        pending
      end
    end
  end

  describe '#sort' do
    after :each do
      Animal.all.each(&:destroy)
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

  describe '#filter' do
    before :all do
      Animal.create({ name: 'a', birthdate: Date.today.at_midnight - 1.year })
      Animal.create({ name: 'b', birthdate: Date.today.at_midnight - 2.years })
      Animal.create({ name: 'c', birthdate: Date.today.at_midnight - 3.years })
    end

    after :all do
      Animal.all.each(&:destroy)
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
      pending('probably doesnt work')
    end
  end

end