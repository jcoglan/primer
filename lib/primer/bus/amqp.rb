require 'mq'

module Primer
  class Bus
    
    class AMQP < Bus
      def initialize(config = {})
        raise "I need a queue name!" unless config[:queue]
        super()
        Faye.ensure_reactor_running!
        @queue = MQ.new.queue(config[:queue])
        @queue.subscribe do |message|
          data = YAML.load(message)
          @listeners.each { |cb| cb.call(data) }
        end
      end
      
      def publish(message)
        @queue.publish(YAML.dump(message))
      end
    end
    
  end
end

