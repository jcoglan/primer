module Primer
  class Bus
    
    class Memory < Bus
      def publish(topic, message)
        distribute(topic, message)
      end
    end
    
  end
end

