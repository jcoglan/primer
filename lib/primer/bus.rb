module Primer
  class Bus
    
    autoload :Memory, ROOT + '/primer/bus/memory'
    autoload :AMQP,   ROOT + '/primer/bus/amqp'
    
    def initialize
      unsubscribe_all
    end
    
    def distribute(topic, message)
      return unless @listeners.has_key?(topic)
      @listeners[topic].each { |cb| cb.call(message) }
    end
    
    def subscribe(topic, &listener)
      @listeners[topic].add(listener)
    end
    
    def unsubscribe(topic, &listener)
      @listeners[topic].delete(listener)
    end
    
    def unsubscribe_all
      @listeners = Hash.new { |h,k| h[k] = Set.new }
    end
    
  end
end

