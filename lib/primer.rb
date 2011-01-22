require 'json'
require 'faye'
require 'set'

module Primer
  ROOT = File.expand_path(File.dirname(__FILE__))
  VERSION = '0.1.0'
  
  class InvalidKey    < StandardError ; end
  class RouteNotFound < StandardError ; end
  
  autoload :Cache,    ROOT + '/primer/cache'
  autoload :Bus,      ROOT + '/primer/bus'
  autoload :RouteSet, ROOT + '/primer/route_set'
  autoload :Enabler,  ROOT + '/primer/enabler'
  autoload :Watcher,  ROOT + '/primer/watcher'
  autoload :Lazyness, ROOT + '/primer/lazyness'
  autoload :Helpers,  ROOT + '/primer/helpers'
  autoload :RealTime, ROOT + '/primer/real_time'
  autoload :Worker,   ROOT + '/primer/worker'
  
  class << self
    attr_accessor :cache, :bus, :real_time
  end
  
  self.bus = Bus::Memory.new
  
  def self.worker!
    Worker.run
  end
  
  def self.serialize(object)
    JSON.unparse([object])
  end
  
  def self.deserialize(string)
    JSON.parse(string).first
  end
end

