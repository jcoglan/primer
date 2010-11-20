dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(dir)

require 'primer'

require 'active_record'
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

ActiveRecord::Schema.define do |version|
  create_table :people, :force => true do |t|
    t.string  :name
    t.integer :age
  end
end

require 'models/watchable'
require 'models/person'
require 'primer/cache_spec'

RSpec.configure do |config|
  config.before do
    Primer::Watcher.disable!
    Primer.cache = nil
  end
  
  config.after do
    Primer::Watcher.reset!
    Primer.cache.clear if Primer.cache
    Person.delete_all
  end
end

