require 'mq'

module Primer
  class Bus
    
    class AMQP < Bus
      def initialize(config = {})
        @config = config
        super()
      end
      
      def publish(topic, message)
        tuple = [topic, message]
        queue.publish(YAML.dump(tuple))
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
        @queue = MQ.new.queue(@config[:queue])
      end
      
      def bind
        return if @bound
        queue.subscribe do |message|
          data = YAML.load(message)
          distribute(*data)
        end
        @bound = true
      end
    end
    
  end
end

