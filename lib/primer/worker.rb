module Primer
  class Worker
    
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
        Primer.cache.bind_to_bus
        
        puts "Listening for messages..."
        puts
      }
    end
    
  end
end

