module Primer
  module Watcher
    
    module ActiveRecordMacros
      def self.extended(klass)
        attributes = klass.columns.map { |c| c.name }
        klass.watch_calls_to(*attributes)
        klass.__send__(:include, InstanceMethods)
        klass.after_update(:notify_primer_after_update)
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
      
      module InstanceMethods
        def primer_identifier
          ['ActiveRecord', self.class.name, read_attribute(self.class.primary_key)]
        end
        
        def notify_primer_after_update
          changes.each do |attribute, (old_value, new_value)|
            Primer.cache.changed(primer_identifier + [attribute.to_s])
          end
        end
      end
    end
    
  end
end

