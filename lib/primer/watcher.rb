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
        
        @primer_patched = true
        
        @primer_watched_calls.each do |method_name|
          safe_name = method_name.to_s.gsub(/[^a-z0-9_]$/i, '')
          class_eval <<-RUBY
            alias :#{safe_name}_before_primer_patch :#{method_name}
            def #{method_name}(*args, &block)
              result = #{safe_name}_before_primer_patch(*args, &block)
              Primer::Watcher.call_log << [self, :#{method_name}, args, block, result]
              result
            end
          RUBY
        end
      end
      
      def unpatch_for_primer!
        return if @primer_watched_calls.nil? or not @primer_patched
        
        @primer_patched = false
        
        @primer_watched_calls.each do |method_name|
          safe_name = method_name.to_s.gsub(/[^a-z0-9_]$/i, '')
          class_eval <<-RUBY
            alias :#{method_name} :#{safe_name}_before_primer_patch
            undef_method :#{safe_name}_before_primer_patch
          RUBY
        end
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

