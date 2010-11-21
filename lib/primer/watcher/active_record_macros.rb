module Primer
  module Watcher
    
    module ActiveRecordMacros
      def self.extended(klass)
        klass.watch_calls_to(*klass.attributes_watchable_by_primer)
        klass.__send__(:include, InstanceMethods)
        klass.after_create(:notify_primer_after_create)
        klass.after_update(:notify_primer_after_update)
      end
      
      def attributes_watchable_by_primer
        attributes = columns + reflect_on_all_associations
        attributes.map { |c| c.name.to_s }
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
          self.class.reflect_on_all_associations.each do |assoc|
            next unless assoc.macro == :belongs_to
            owner = __send__(assoc.name)
            next unless owner
            mirror = owner.class.reflect_on_all_associations.find do |mirror_assoc|
              mirror_assoc.macro == :has_many and
              mirror_assoc.class_name == self.class.name
            end
            next unless mirror
            Primer.cache.changed(owner.primer_identifier + [mirror.name.to_s])
          end
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

