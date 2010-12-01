module Primer
  module Watcher
    
    extend Enabler
    autoload :Macros,             ROOT + '/primer/watcher/macros'
    autoload :ActiveRecordMacros, ROOT + '/primer/watcher/active_record_macros'
    
    def self.included(klass)
      klass.extend(Macros)
    end
    
    def self.reset!
      Thread.current[:primer_call_log] = []
      Thread.current[:primer_loggers]  = nil
    end
    
    def self.call_log
      Thread.current[:primer_call_log] ||= []
    end
    
    def self.log(receiver, method_name, args, block, result)
      call = [receiver, method_name, args, block, result]
      loggers.each { |logger| logger << call }
    end
    
    def self.loggers
      Thread.current[:primer_loggers] ||= [call_log]
    end
    
    def self.on_enable
      ObjectSpace.each_object(Macros) { |klass| klass.patch_for_primer! }
    end
    
    def self.on_disable
      ObjectSpace.each_object(Macros) { |klass| klass.unpatch_for_primer! }
    end
    
    def self.watching(calls = [])
      @active_watching_blocks ||= 0
      @active_watching_blocks += 1
      was_enabled = enabled?
      enable!
      loggers << calls
      result = yield
      loggers.pop
      @active_watching_blocks -= 1
      disable! if @active_watching_blocks.zero? and not was_enabled
      result
    end
    
    def primer_identifier
      ['Object', self.class.name, object_id]
    end
    
  end
end

