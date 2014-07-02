require 'spec_helper'

describe ElasticQueue::Query do
  before :all do
    class Animal < ActiveRecord::Base
      include ElasticQueue::Queueable
      queues :test_animals_queue
      queue_attributes :dangerous, :cute, :birthdate
      not_analyzed_queue_attributes :species, :description, :name
      after_save :index_for_queues
      before_destroy :remove_from_queue_indices
    end

    class TestAnimalsQueue < ElasticQueue::Base
      models :animal
    end

    TestAnimalsQueue.create_index

    animals = []
    (0...55).each { |name| animals << { name: name } }
    Animal.create(animals)
  end

  after :all do
    Animal.all.each(&:destroy)
    [:Animal, :TestAnimalsQueue].each do |constant|
      Object.send(:remove_const, constant)
    end
    delete_index('test_animals_queue')
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
  end

  describe '#count' do
    it 'returns the count of the number of results' do
     expect(TestAnimalsQueue.query.all.count).to be 55
    end

    it 'does not make elasticsearch fetch all the records' do
      TestAnimalsQueue.search_client.stub(:search) { { hits: { total: 0, hits: [] } } }
      TestAnimalsQueue.search_client.should_receive(:search).with({ index: 'test_animals_queue', body: {}, search_type: 'count' })
      TestAnimalsQueue.query.count
    end
  end
end