dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(dir)

require 'primer'
require 'tilt'
require 'erb'
require 'action_controller'

require 'fileutils'
require 'active_record'
FileUtils.mkdir_p(dir + '/db')
ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => dir + '/db/test.sqlite3')

ActiveRecord::Schema.define do |version|
  create_table :blog_posts, :force => true do |t|
    t.belongs_to :person
    t.string :title
  end
  
  create_table :people, :force => true do |t|
    t.string  :name
    t.integer :age
  end
end

require 'models/watchable'
require 'models/blog_post'
require 'models/person'

RSpec.configure do |config|
  config.before do
    Primer::Watcher.disable!
    Primer.bus = Primer::Bus::Memory.new
    Primer.cache = nil
    Primer.real_time = false
  end
  
  config.after do
    if Primer.cache
      Primer.cache.clear
      Primer.cache.routes = nil
    end
    Primer::Watcher.reset!
    Primer.bus.unsubscribe_all
    [BlogPost, Person].each { |m| m.delete_all }
  end
end

