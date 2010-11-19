module Primer
  module Cache
    
    class Memory
      def initialize
        @store = {}
      end
      
      def compute(cache_key)
        @store.has_key?(cache_key) ? @store[cache_key] : put(cache_key, yield)
      end
      
      def put(cache_key, value)
        @store[cache_key] = value
      end
    end
    
  end
end

