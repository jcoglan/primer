module Primer
  module Worker
    
    class ConfigError < StandardError ; end
    
    autoload :ActiveRecordAgent, ROOT + '/primer/worker/active_record_agent'
    
    def self.run
      raise ConfigError.new('No cache present') unless Primer.cache
      raise ConfigError.new('No message bus present') unless Primer.bus
      
      puts "Cache: #{ Primer.cache }"
      puts "Message bus: #{ Primer.bus }"
      puts
      
      EM.run {
        ActiveRecordAgent.bind_to_bus
        bind_to_queue 'changes'
        
        puts "Listening for messages..."
        puts
      }
    end
    
    def self.bind_to_queue(queue_name)
      Primer.bus.subscribe(queue_name) do |message|
        klass    = constantize(message['class_name'])
        instance = klass.from_primer_identifier(message['object']) rescue klass.new
        method   = "#{message['method']}_before_primer_worker_patch"
        instance.__send__(method, *message['arguments'])
      end
    end
    
    def self.constantize(class_name)
      class_name.split('::').inject(Kernel, &:const_get)
    end
    
    def self.included(klass)
      klass.extend(Macros)
    end
    
    module Macros
      def self.alias_name(method_name)
        method_name.to_s.gsub(/[^a-z0-9_]$/i, '') + '_before_primer_worker_patch'
      end
      
      def dispatch_to_worker(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        args.each do |method_name|
          dispatch_method_to_worker(method_name, options)
        end
      end
      
      def dispatch_method_to_worker(method_name, options)
        alias_name = Macros.alias_name(method_name)
        queue_name = options[:queue]
        return unless instance_method(method_name) rescue nil
        class_eval <<-RUBY
          alias :#{alias_name} :#{method_name}
          def #{method_name}(*args, &block)
            Primer.bus.publish(:#{queue_name},
              'class_name' => self.class.name,
              'object'     => primer_identifier,
              'method'     => '#{method_name}',
              'arguments'  => args)
            Primer::Worker::Result.new
          end
        RUBY
      end
    end
    
    class Result
      include EventMachine::Deferrable
    end
    
  end
end

