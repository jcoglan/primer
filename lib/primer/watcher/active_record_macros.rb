module Primer
  module Watcher
    
    module ActiveRecordMacros
      def self.extended(klass)
        attributes = klass.columns.map { |c| c.name }
        klass.watch_calls_to(*attributes)
      end
      
      def patch_method_for_primer(method_name)
        method = instance_method(method_name) rescue nil
        return super if method
        class_eval <<-RUBY
          def #{method_name}
            result = read_attribute(:#{method_name})
            Primer::Watcher.log(self, :#{method_name}, [], nil, result)
            result
          end
        RUBY
      end
      
      def unpatch_method_for_primer(method_name)
        alias_name = Macros.alias_name(method_name)
        method = instance_method(alias_name) rescue nil
        return super if method
        class_eval <<-RUBY
          undef_method :#{method_name}
        RUBY
      end
    end
    
  end
end

