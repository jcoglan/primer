module Primer
  class Bus
    
    autoload :Memory, ROOT + '/primer/bus/memory'
    autoload :AMQP,   ROOT + '/primer/bus/amqp'
    
    def initialize
      unsubscribe_all
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

