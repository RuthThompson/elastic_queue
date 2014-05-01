# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'rspec'
require 'rspec/autorun'

require 'factory_girl'
require File.expand_path('../../lib/elastic_queue', __FILE__)
require 'support/elastic_queue_helper'
require 'support/database_helper'

DatabaseHelper.new({ :adapter  => 'sqlite3', :database => './spec/eq_test.db' }).initialize_db

RSpec.configure do |config|
  config.order = 'random'
  config.color_enabled = true
  config.include FactoryGirl::Syntax::Methods
  config.include(ElasticQueueHelper)
end