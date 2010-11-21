require 'set'

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
      
      def changed(attribute)
        return unless keys = @relations[attribute]
        keys = keys.to_a
        keys.each { |key| invalidate(key) }
        regenerate(keys)
      end
    end
    
  end
end

