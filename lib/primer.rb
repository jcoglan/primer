module Primer
  ROOT = File.expand_path(File.dirname(__FILE__))
  
  autoload :Cache,   ROOT + '/primer/cache'
  autoload :Enabler, ROOT + '/primer/enabler'
  autoload :Watcher, ROOT + '/primer/watcher'
  autoload :Helpers, ROOT + '/primer/helpers'
  
  class << self
    attr_accessor :cache
  end
end

