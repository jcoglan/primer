require 'mq'

module Primer
  class Bus
    
    class AMQP < Bus
      def initialize(config = {})
        @config = config
        super()
      end
      
      def publish(message)
        queue.publish(YAML.dump(message))
      end
      
      def subscribe
        bind
        super
      end
      
    private
      
      def queue
        Faye.ensure_reactor_running!
        return @queue if defined?(@queue)
        raise "I need a queue name!" unless @config[:queue]
        @queue = MQ.new.queue(@config[:queue])
      end
      
      def bind
        return if @bound
        queue.subscribe do |message|
          data = YAML.load(message)
          @listeners.each { |cb| cb.call(data) }
        end
        @bound = true
      end
    end
    
  end
end

