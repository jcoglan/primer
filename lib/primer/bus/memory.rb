module Primer
  module Bus
    
    class Memory
      def initialize
        unsubscribe_all
      end
      
      def publish(message)
        @listeners.each { |cb| cb.call(message) }
      end
      
      def subscribe(&listener)
        @listeners.add(listener)
      end
      
      def unsubscribe(&listener)
        @listeners.delete(listener)
      end
      
      def unsubscribe_all
        @listeners = Set.new
      end
    end
    
  end
end

