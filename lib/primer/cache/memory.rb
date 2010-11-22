module Primer
  class Cache
    
    class Memory < Cache
      def initialize
        clear
      end
      
      def clear
        @data_store   = {}
        @relations    = {}
        @dependencies = {}
      end
      
      def put(cache_key, value)
        validate_key(cache_key)
        @data_store[cache_key] = value
        publish_change(cache_key)
      end
      
      def get(cache_key)
        validate_key(cache_key)
        @data_store[cache_key]
      end
      
      def has_key?(cache_key)
        @data_store.has_key?(cache_key)
      end
      
      def invalidate(cache_key)
        @data_store.delete(cache_key)
        return unless deps = @dependencies[cache_key]
        deps.each do |attribute|
          @relations[attribute].delete(cache_key)
        end
        @dependencies.delete(cache_key)
      end
      
      def relate(cache_key, attributes)
        deps = @dependencies[cache_key] ||= Set.new
        attributes.each do |attribute|
          deps.add(attribute)
          list = @relations[attribute] ||= Set.new
          list.add(cache_key)
        end
      end
      
      def keys_for_attribute(attribute)
        return [] unless keys = @relations[attribute]
        keys.to_a
      end
      
      def timeout(cache_key, &block)
        add_timeout(cache_key, @throttle, &block)
      end
    end
    
  end
end

