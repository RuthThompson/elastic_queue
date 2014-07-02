require 'spec_helper'

describe 'ElasticQueue::Queueable integration' do
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
  end

  after :all do
    [:Animal, :TestAnimalsQueue].each do |constant|
      Object.send(:remove_const, constant)
    end
  end

  # TODO: Turn back on later
  # describe '#add_queue' do
  #   after :each do
  #     [:SomeModel, :SomeOtherModel, :SomeQueue, :SomeOtherQueue].each do |constant|
  #       Object.send(:remove_const, constant) if Object.constants.include? constant
  #     end
  #   end
  #   it 'adds a queue to its list of queues' do
  #     class SomeModel < ActiveRecord::Base
  #       include ElasticQueue::Queueable
  #     end
  #     class SomeQueue < ElasticQueue::Base
  #     end
  #     SomeModel.add_queue(:some_queue)
  #     expect(SomeModel.queues.sort).to eq [:some_queue]
  #   end
  # 
  #   it 'only adds each queue once' do
  #     class SomeOtherModel < ActiveRecord::Base
  #       include ElasticQueue::Queueable
  #     end
  #     class SomeQueue < ElasticQueue::Base
  #     end
  #     class SomeOtherQueue < ElasticQueue::Base
  #     end
  #     SomeOtherModel.add_queue(:some_queue)
  #     SomeOtherModel.add_queue(:some_other_queue)
  #     SomeOtherModel.add_queue(:some_queue)
  #     expect(SomeOtherModel.queues.sort).to eq [:some_other_queue, :some_queue]
  #   end
  # end
end
