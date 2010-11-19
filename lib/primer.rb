module Primer
  autoload :Cache,   'primer/cache'
  autoload :Enabler, 'primer/enabler'
  autoload :Watcher, 'primer/watcher'
  
  class << self
    attr_accessor :cache
  end
end

