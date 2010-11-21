require 'redis'

module Primer
  class Cache
    
    class Redis < Cache
      REDIS_CONFIG = {:thread_safe => true}
      
      def initialize(config = {})
        config = REDIS_CONFIG.merge(config)
        @redis = ::Redis.new(config)
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
      
      def keys_for_attribute(attribute)
        serial = attribute.join('/')
        has_key?(serial) ? @redis.smembers(serial) : []
      end
      
      def timeout(cache_key, &block)
        return block.call unless @throttle
        return if has_key?('timeouts' + cache_key)
        @redis.set('timeouts' + cache_key, 'true')
        add_timeout(cache_key, @throttle) do
          block.call
          @redis.del('timeouts' + cache_key)
        end
      end
    end
    
  end
end

