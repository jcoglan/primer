module Primer
  module Watcher
    
    extend Enabler
    autoload :Macros,             'primer/watcher/macros'
    autoload :ActiveRecordMacros, 'primer/watcher/active_record_macros'
    
    def self.included(klass)
      klass.extend(Macros)
      @classes ||= []
      @classes << klass
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
      @classes.each { |klass| klass.patch_for_primer! }
    end
    
    def self.on_disable
      @classes.each { |klass| klass.unpatch_for_primer! }
    end
    
    def self.watching(calls = [])
      enable!
      loggers << calls
      result = yield
      loggers.pop
      result
    end
    
    def primer_identifier
      ['Object', self.class.name, object_id]
    end
    
  end
end

