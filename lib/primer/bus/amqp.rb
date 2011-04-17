require 'amqp'

module Primer
  class Bus
    
    class AMQP < Bus
      def initialize(config = {})
        @config = config
        super()
      end
      
      def publish(topic, message)
        tuple = [topic.to_s, message]
        queue.publish(Primer.serialize(tuple))
      end
      
      def subscribe(*args, &block)
        bind
        super
      end
      
    private
      
      def queue
        Faye.ensure_reactor_running!
        return @queue if defined?(@queue)
        raise "I need a queue name!" unless @config[:queue]
        amqp_klass = defined?(MQ) ? MQ : ::AMQP::Channel
        @queue = amqp_klass.new.queue(@config[:queue])
      end
      
      def bind
        return if @bound
        queue.subscribe do |message|
          data = Primer.deserialize(message)
          distribute(*data)
        end
        @bound = true
      end
    end
    
  end
end

