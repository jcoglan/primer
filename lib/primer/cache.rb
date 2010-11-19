module Primer
  class Cache
    autoload :Memory, ROOT + '/primer/cache/memory'
    autoload :Redis,  ROOT + '/primer/cache/redis'
    
    def compute(cache_key, &block)
      return get(cache_key) if has_key?(cache_key)
      
      calls = []
      result = Watcher.watching(calls, &block)
      
      attributes = calls.map do |(receiver, method_name, args, block, return_value)|
        receiver.primer_identifier + [method_name.to_s]
      end
      
      relate(cache_key, attributes)
      put(cache_key, result)
      
      result
    end
  end
end

