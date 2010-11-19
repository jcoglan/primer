module Primer
  module Watcher
    
    extend Enabler
    
    module Macros
      attr_reader :primer_watched_calls
      
      def watch_calls_to(*methods)
        @primer_watched_calls ||= []
        @primer_watched_calls += methods
      end
      
      def patch_for_primer!
        return if @primer_watched_calls.nil? or @primer_patched
        
        @primer_patched_methods = {}
        @primer_patched = true
        
        @primer_watched_calls.each do |method_name|
          @primer_patched_methods[method_name] = instance_method(method_name)
          class_eval <<-RUBY
            def #{method_name}(*args, &block)
              method = self.class.instance_eval { @primer_patched_methods[:#{method_name}] }
              result = method.bind(self).call(*args, &block)
              Primer::Watcher.call_log << [self, :#{method_name}]
              result
            end
          RUBY
        end
      end
      
      def unpatch_for_primer!
        return if @primer_watched_calls.nil? or not @primer_patched
      end
    end
    
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

