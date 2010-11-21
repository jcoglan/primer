require 'redis'

module Primer
  class Cache
    
    class Redis < Cache
      def initialize(config = {})
        @redis = ::Redis.new(config)
        bind_to_bus
      end
      
      def clear
        @redis.flushdb
      end
      
      def put(cache_key, value)
        validate_key(cache_key)
        @redis.set(cache_key, YAML.dump(value))
        publish_change(cache_key)
        RealTime.publish(cache_key, value)
      end
      
      def get(cache_key)
        validate_key(cache_key)
        string = @redis.get(cache_key)
        string ? YAML.load(string) : nil
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
        keys = @redis.smembers(serial)
        keys.each { |key| invalidate(key) }
        regenerate(keys)
      end
    end
    
  end
end

