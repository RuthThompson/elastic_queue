require 'spec_helper'

describe 'ElasticQueue::Base integration' do
  describe '#search_client' do
    it 'returns an Elasticsearch::Transport::Client' do
      expect(ElasticQueue::Base.search_client).to be_a Elasticsearch::Transport::Client
    end
    
    it 'returns the same client every time' do
      expect(ElasticQueue::Base.search_client.object_id).to eq ElasticQueue::Base.search_client.object_id
    end
  end

  describe '#models, also tests(#tell_models, #model_names, #model_classes)' do
    it '#models sets @models and tells the model about itself' do
      class Cannibal < ActiveRecord::Base
        include ElasticQueue::Queueable
      end
      Cannibal.stub(:add_queue)
      Cannibal.should_receive(:add_queue).with(:"elastic_queue/base")
      ElasticQueue::Base.models(:cannibal)
      expect(ElasticQueue::Base.instance_variable_get('@models')).to eq [:cannibal]
    end
  end

  describe '#index_name, #index_name =' do
    pending('trivial')
  end

  describe '#eager_load' do
    pending
  end

  describe '#eager_loads' do
    pending
  end

  describe '#scopes' do
    pending
  end

  describe '#scopes' do
    pending
  end

  describe '#default_scope' do
    pending
  end

  describe '#query' do
    pending
  end

  describe '#filter' do
    pending
  end
 
  describe '#count' do
    pending
  end

  describe '#paginate' do
    pending('not implemented yet')
  end

  describe 'instance #query' do
    pending
  end

end