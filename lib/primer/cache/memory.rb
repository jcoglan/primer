module Primer
  module Cache
    
    class Memory
      def initialize
        @data_store = {}
        @relations  = {}
      end
      
      def compute(cache_key, &block)
        return @data_store[cache_key] if @data_store.has_key?(cache_key)
        
        calls = []
        result = Watcher.watching(calls, &block)
        
        attributes = calls.map do |(receiver, method_name, args, block, return_value)|
          receiver.primer_identifier + [method_name.to_s]
        end
        
        relate(cache_key, attributes)
        put(cache_key, result)
      end
      
      def put(cache_key, value)
        @data_store[cache_key] = value
      end
      
      def get(cache_key)
        @data_store[cache_key]
      end
      
      def invalidate(cache_key)
        @data_store.delete(cache_key)
      end
      
      def relate(cache_key, attributes)
        attributes.each do |attribute|
          list = @relations[attribute] ||= []
          list << cache_key
        end
      end
      
      def changed(attribute)
        return unless keys = @relations[attribute]
        keys.each { |key| invalidate(key) }
      end
    end
    
  end
end

