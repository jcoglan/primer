module Primer
  class Bus
    
    class Memory < Bus
      def publish(message)
        @listeners.each { |cb| cb.call(message) }
      end
    end
    
  end
end

