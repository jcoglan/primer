module Primer
  module Watcher
    
    module Macros
      def self.extended(klass)
        if defined?(ActiveRecord) and klass < ActiveRecord::Base
          klass.extend(ActiveRecordMacros)
        end
      end
      
      def self.alias_name(method_name)
        method_name.to_s.gsub(/[^a-z0-9_]$/i, '') + 'before_primer_watcher_patch'
      end
      
      def primer_watched_calls
        @primer_watched_calls ||= (Macros === superclass) ?
                                  superclass.primer_watched_calls.dup :
                                  Set.new
      end
      
      def watch_calls_to(*methods)
        method_names = methods.map { |m| m.to_s }
        primer_watched_calls.merge(method_names)
      end
      
      def patch_for_primer!
        return if @primer_patched
        @primer_patched = true
        primer_watched_calls.each do |method_name|
          patch_method_for_primer(method_name)
        end
      end
      
      def patch_method_for_primer(method_name)
        alias_name = Macros.alias_name(method_name)
        return unless method = instance_method(method_name) rescue nil
        class_eval <<-RUBY
          alias :#{alias_name} :#{method_name}
          def #{method_name}(*args, &block)
            result = #{alias_name}(*args, &block)
            Primer::Watcher.log(self, :#{method_name}, args, block, result)
            result
          end
        RUBY
      end
      
      def unpatch_for_primer!
        return unless @primer_patched
        @primer_patched = false
        primer_watched_calls.each do |method_name|
          unpatch_method_for_primer(method_name)
        end
      end
      
      def unpatch_method_for_primer(method_name)
        alias_name = Macros.alias_name(method_name)
        return unless method = instance_method(alias_name) rescue nil
        class_eval <<-RUBY
          alias :#{method_name} :#{alias_name}
          undef_method :#{alias_name}
        RUBY
      end
    end
    
  end
end

