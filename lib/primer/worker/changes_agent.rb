module Primer
  class Worker
    
    class ChangesAgent
      def self.run!
        Primer.bus.subscribe :changes do |attribute|
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
end
