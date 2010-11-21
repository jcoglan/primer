module Primer
  class Cache
    
    autoload :Memory, ROOT + '/primer/cache/memory'
    autoload :Redis,  ROOT + '/primer/cache/redis'
    
    attr_accessor :routes
    
    def routes(&block)
      @routes ||= RouteSet.new
      @routes.instance_eval(&block)
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
        receiver.primer_identifier + [method_name.to_s]
      end
      
      unless result.nil?
        relate(cache_key, attributes)
        put(cache_key, result)
      end
      
      result
    end
    
    def regenerate(keys)
      keys.each { |cache_key| compute(cache_key) rescue nil }
    end
    
  end
end

