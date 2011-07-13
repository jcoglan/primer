module Primer
  module Watcher
    
    module ActiveRecordMacros
      def self.extended(klass)
        klass.watch_calls_to(*klass.attributes_watchable_by_primer)
        klass.__send__(:include, InstanceMethods)
        klass.after_create(:notify_primer_after_create)
        klass.after_update(:notify_primer_after_update)
        klass.after_destroy(:notify_primer_after_destroy)
      end
      
      def has_many(name, *args)
        watch_calls_to(name)
        super
      end
      
      def belongs_to(name, *args)
        watch_calls_to(name)
        super
      end
      
      def attributes_watchable_by_primer
        attributes = columns + reflect_on_all_associations
        attributes.map { |c| c.name.to_s }
      end
      
      def primer_foreign_key_mappings
        return @primer_foreign_key_mappings if defined?(@primer_foreign_key_mappings)
        
        foreign_keys = reflect_on_all_associations.
                       select { |a| a.macro == :belongs_to }.
                       map { |a| [a.primary_key_name.to_s, a.name] }
        
        @primer_foreign_key_mappings = Hash[foreign_keys]
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
        
        def notify_primer_after_create
          Primer.bus.publish(:active_record, ['create', self.class.name, attributes])
        end
        
        def notify_primer_after_update
          Primer.bus.publish(:active_record, ['update', self.class.name, attributes, changes])
        end
        
        def notify_primer_after_destroy
          Primer.bus.publish(:active_record, ['destroy', self.class.name, attributes])
        end
      end
    end
    
  end
end

