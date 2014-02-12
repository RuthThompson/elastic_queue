require 'rubygems'
require 'active_record'
require 'elasticsearch'
require 'spec_helper'

describe ElasticQueue::Base do

  before(:all) do
    class Carrot < ActiveRecord::Base
    end
    
    class Cabbage < ActiveRecord::Base
    end

    class TestQueue < ElasticQueue::Base
    end

    @test_queue = TestQueue
    @test_queue.send(:models, :carrot, :cabbage)
    @test_queue.send(:eager_load, :brussels_sprouts)
  end

  describe '#search_client' do
    pending
  end

  describe 'naming:' do
    describe '#index_name' do
      it 'returns the correct index name' do
        expect('test_queue') == @test_queue.index_name
      end
    end

    describe '#models and #model_names' do
      it 'complains if the user hasn\'t set any models' do
        class TestQueue2 < ElasticQueue::Base
        end
        expect{TestQueue2.model_names}.to raise_error(NotImplementedError)
      end

      it 'returns the correct model names' do
        expect(@test_queue.model_names).to eq([:carrot, :cabbage])
      end
    end

    describe '#model_classes' do
      it 'returns the correct model classes' do
        expect(@test_queue.model_classes).to eq([Carrot, Cabbage])
      end
    end

    describe '#eager_load and #eager_loads' do
      pending
    end

    describe '#query' do
      it 'returns a query object for itself' do
        expect(@test_queue.query).to be_a(ElasticQueue::Query)
        expect(@test_queue.query.instance_variable_get('@queue')).to be(@test_queue)
      end
    end

    describe '#filter' do
      pending
    end

    describe '#count' do
      pending
    end
  end
end