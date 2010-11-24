module Primer
  module Watcher
    
    module ActiveRecordMacros
      def self.mirror_association(object, related, macro)
        related.class.reflect_on_all_associations.find do |mirror_assoc|
          mirror_assoc.macro == macro and
          mirror_assoc.class_name == object.class.name
        end
      end
      
      def self.notify_attributes(instance, fields)
        foreign_keys = instance.class.primer_foreign_key_mappings
        
        fields.each do |attribute, value|
          Primer.bus.publish(:changes, instance.primer_identifier + [attribute.to_s])
          if assoc = foreign_keys[attribute.to_s]
            Primer.bus.publish(:changes, instance.primer_identifier + [assoc.to_s])
          end
        end
      end
      
      def self.notify_belongs_to_associations(instance)
        instance.class.reflect_on_all_associations.each do |assoc|
          next unless assoc.macro == :belongs_to
          
          owner = instance.__send__(assoc.name)
          next unless owner
          
          mirror = ActiveRecordMacros.mirror_association(instance, owner, :has_many)
          next unless mirror
          
          Primer.bus.publish(:changes, owner.primer_identifier + [mirror.name.to_s])
          notify_has_many_through_association(owner, mirror.name)
        end
      end
      
      def self.notify_has_many_associations(instance)
        instance.class.reflect_on_all_associations.each do |assoc|
          next unless assoc.macro == :has_many
          next if assoc.options[:dependent] == :destroy
          
          instance.__send__(assoc.name).each do |object|
            mirror = ActiveRecordMacros.mirror_association(instance, object, :belongs_to)
            next unless mirror
            
            Primer.bus.publish(:changes, object.primer_identifier + [mirror.name.to_s])
          end
        end
      end
      
      def self.notify_has_many_through_association(instance, through_name)
        instance.class.reflect_on_all_associations.each do |assoc|
          next unless assoc.macro == :has_many and assoc.options[:through] == through_name
          Primer.bus.publish(:changes, instance.primer_identifier + [assoc.name.to_s])
        end
      end
      
      def self.extended(klass)
        klass.watch_calls_to(*klass.attributes_watchable_by_primer)
        klass.__send__(:include, InstanceMethods)
        klass.after_create(:notify_primer_after_create)
        klass.after_update(:notify_primer_after_update)
        klass.after_destroy(:notify_primer_after_destroy)
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
          ActiveRecordMacros.notify_belongs_to_associations(self)
        end
        
        def notify_primer_after_update
          ActiveRecordMacros.notify_attributes(self, changes)
        end
        
        def notify_primer_after_destroy
          ActiveRecordMacros.notify_attributes(self, attributes)
          ActiveRecordMacros.notify_belongs_to_associations(self)
          ActiveRecordMacros.notify_has_many_associations(self)
        end
      end
    end
    
  end
end

