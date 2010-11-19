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
    end
    
    def self.call_log
      Thread.current[:primer_call_log]
    end
    
    def self.on_enable
      @classes.each { |klass| klass.patch_for_primer! }
    end
    
    def self.on_disable
      @classes.each { |klass| klass.unpatch_for_primer! }
    end
    
  end
end

