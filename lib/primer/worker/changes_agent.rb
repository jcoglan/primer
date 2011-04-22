module Primer
  class Worker
    
    class ChangesAgent < Agent
      topic :changes
      
      def on_message(attribute)
        cache = Primer.cache
        cache.keys_for_attribute(attribute).each do |cache_key|
          block = lambda do
            cache.invalidate(cache_key)
            cache.regenerate(cache_key)
          end
          cache.throttle ? cache.timeout(cache_key, &block) : block.call
        end
      end
    end
    
  end
end
