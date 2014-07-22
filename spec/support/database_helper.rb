require 'active_record'
require 'sqlite3'

class DatabaseHelper

  def initialize(opts)
    @opts = opts
  end

  def initialize_db
    ActiveRecord::Base.establish_connection(@opts)
    drop_tables
    initialize_tables
  end

  def initialize_tables
    ActiveRecord::Migration.class_eval do
      create_table :animals do |t|
        t.string   :name
        t.string   :species
        t.datetime :birthdate
        t.boolean  :dangerous
        t.boolean  :cute
        t.text     :description
      end

      create_table :plants do |t|
        t.string   :name
        t.string   :species
        t.boolean  :poisonous
        t.boolean  :edible
        t.text     :description
      end
    end
  end

  def drop_tables
    if ActiveRecord::Base.connection.table_exists? 'animals'
      ActiveRecord::Migration.class_eval do
        drop_table :animals
      end
    end
    if ActiveRecord::Base.connection.table_exists? 'plants'
      ActiveRecord::Migration.class_eval do
        drop_table :plants
      end
    end
  end

end