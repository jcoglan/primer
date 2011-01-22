module Primer
  class Bus
    
    class Memory < Bus
      def publish(topic, message)
        return distribute(topic, message) unless @config[:async]
        EM.add_timer(0.1) { distribute(topic, message) }
      end
    end
    
  end
end

