# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'rspec'
require 'rspec/autorun'
require 'factory_girl'
require File.expand_path('../../lib/elastic_queue', __FILE__)
require 'support/elastic_queue_helper'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
# Dir['spec/support/**/*.rb'].each { |f| require f }
# require_relative '../../lib/elastic_queue'

RSpec.configure do |config|
  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
  config.color_enabled = true

  config.include FactoryGirl::Syntax::Methods
  config.include(ElasticQueueHelper)
end