module Primer
  class Cache
    
    autoload :Memory, ROOT + '/primer/cache/memory'
    autoload :Redis,  ROOT + '/primer/cache/redis'
    
    attr_writer :routes
    
    def compute(cache_key)
      return get(cache_key) if has_key?(cache_key)
      
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
    
  end
end

