module Primer
  ROOT = File.expand_path(File.dirname(__FILE__))
  VERSION = '0.1.0'
  
  autoload :Cache,    ROOT + '/primer/cache'
  autoload :RouteSet, ROOT + '/primer/route_set'
  autoload :Enabler,  ROOT + '/primer/enabler'
  autoload :Watcher,  ROOT + '/primer/watcher'
  autoload :Helpers,  ROOT + '/primer/helpers'
  
  class << self
    attr_accessor :cache
  end
end

