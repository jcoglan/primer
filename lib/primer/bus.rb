module Primer
  class Bus
    
    autoload :Memory, ROOT + '/primer/bus/memory'
    autoload :AMQP,   ROOT + '/primer/bus/amqp'
    
    def initialize
      unsubscribe_all
    end
    
    def distribute(topic, message)
      topic = topic.to_s
      return unless @listeners.has_key?(topic)
      @listeners[topic].each { |cb| cb.call(message) }
    end
    
    def subscribe(topic, &listener)
      @listeners[topic.to_s].add(listener)
    end
    
    def unsubscribe(topic, &listener)
      @listeners[topic.to_s].delete(listener)
    end
    
    def unsubscribe_all
      @listeners = Hash.new { |h,k| h[k] = Set.new }
    end
    
  end
end

