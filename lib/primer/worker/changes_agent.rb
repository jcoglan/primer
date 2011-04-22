module Primer
  class Worker
    
    class ChangesAgent < Agent
      def run!
        Primer.bus.subscribe(:changes) { |attribute|
          cache = Primer.cache
          cache.keys_for_attribute(attribute).each do |cache_key|
            block = lambda do
              cache.invalidate(cache_key)
              cache.regenerate(cache_key)
            end
            cache.throttle ? cache.timeout(cache_key, &block) : block.call
          end
        }
      end
    end
    
  end
end
