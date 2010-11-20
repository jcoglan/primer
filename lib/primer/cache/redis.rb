require 'redis'

module Primer
  class Cache
    
    class Redis < Cache
      def initialize(config = {})
        @redis = ::Redis.new(config)
      end
      
      def clear
        @redis.flushdb
      end
      
      def put(cache_key, value)
        @redis.set(cache_key, value)
      end
      
      def get(cache_key)
        @redis.get(cache_key)
      end
      
      def has_key?(cache_key)
        @redis.exists(cache_key)
      end
      
      def invalidate(cache_key)
        @redis.del(cache_key)
        return unless has_key?('deps' + cache_key)
        @redis.smembers('deps' + cache_key).each do |attribute|
          @redis.srem(attribute, cache_key)
        end
        @redis.del('deps' + cache_key)
      end
      
      def relate(cache_key, attributes)
        attributes.each do |attribute|
          serial = attribute.join('/')
          @redis.sadd('deps' + cache_key, serial)
          @redis.sadd(serial, cache_key)
        end
      end
      
      def changed(attribute)
        serial = attribute.join('/')
        return unless has_key?(serial)
        @redis.smembers(serial).each { |key| invalidate(key) }
      end
    end
    
  end
end

