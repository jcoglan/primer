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

require 'schema'

require 'models/watchable'
require 'models/artist'
require 'models/concert'
require 'models/performance'
require 'models/blog_post'
require 'models/person'

module Helper
  def self.next_id
    @next_id ||= 0
    @next_id += 1
    @next_id
  end
end

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
    [BlogPost, Person, Artist, Concert, Performance].each { |m| m.delete_all }
  end
end

