module Primer
  class Cache
    
    autoload :Memory, ROOT + '/primer/cache/memory'
    autoload :Redis,  ROOT + '/primer/cache/redis'
    
    include Watcher
    watch_calls_to :get
    
    include Faye::Timeouts
    
    attr_accessor :throttle
    attr_writer :routes
    
    def primer_identifier
      [Cache.name]
    end
    
    def routes(&block)
      @routes ||= RouteSet.new
      @routes.instance_eval(&block) if block_given?
      @routes
    end
    
    def compute(cache_key)
      return get(cache_key) if has_key?(cache_key)
      
      unless block_given? or @routes
        message = "Cannot call Cache#compute(#{cache_key}) with no block: no routes have been configured"
        raise RouteNotFound.new(message)
      end
      
      calls = []
      result = Watcher.watching(calls) do
        block_given? ? yield : @routes.evaluate(cache_key)
      end
      
      attributes = calls.map do |(receiver, method_name, args, block, return_value)|
        receiver.primer_identifier + [method_name.to_s] + args
      end
      
      unless result.nil?
        relate(cache_key, attributes)
        put(cache_key, result)
      end
      
      result
    end
    
    def regenerate(cache_key)
      compute(cache_key) rescue nil
    end
    
  private
    
    def publish_change(cache_key)
      Primer.bus.publish(:changes, primer_identifier + ['get', cache_key])
    end
    
    def validate_key(cache_key)
      raise InvalidKey.new(cache_key) unless Cache.valid_key?(cache_key)
    end
    
    def self.valid_key?(cache_key)
      Faye::Channel.valid?(cache_key)
    end
    
  end
end

