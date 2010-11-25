module Primer
  class Worker
    
    class ActiveRecordAgent
      def self.bind_to_bus
        Primer.bus.subscribe :active_record do |event, class_name, attributes, changes|
          model = class_name.constantize.new(attributes)
          model.instance_eval do
            @attributes = attributes
            @changed_attributes = changes if changes
          end
          __send__("on_#{event}", model)
        end
      end
      
      def self.macros
        Watcher::ActiveRecordMacros
      end
      
      def self.on_create(model)
        notify_belongs_to_associations(model)
      end
      
      def self.on_update(model)
        notify_attributes(model, model.changes)
      end
      
      def self.on_destroy(model)
        notify_attributes(model, model.attributes)
        notify_belongs_to_associations(model)
        notify_has_many_associations(model)
      end
      
      def self.notify_attributes(model, fields)
        foreign_keys = model.class.primer_foreign_key_mappings
        
        fields.each do |attribute, value|
          Primer.bus.publish(:changes, model.primer_identifier + [attribute.to_s])
          if assoc = foreign_keys[attribute.to_s]
            Primer.bus.publish(:changes, model.primer_identifier + [assoc.to_s])
          end
        end
      end
      
      def self.notify_belongs_to_associations(model)
        model.class.reflect_on_all_associations.each do |assoc|
          next unless assoc.macro == :belongs_to
          
          owner = model.__send__(assoc.name)
          next unless owner
          
          mirror = mirror_association(model, owner, :has_many)
          next unless mirror
          
          Primer.bus.publish(:changes, owner.primer_identifier + [mirror.name.to_s])
          notify_has_many_through_association(owner, mirror.name)
        end
      end
      
      def self.notify_has_many_associations(model)
        model.class.reflect_on_all_associations.each do |assoc|
          next unless assoc.macro == :has_many
          next if assoc.options[:dependent] == :destroy
          
          model_id = model.__send__(model.class.primary_key)
          klass    = assoc.class_name.constantize
          related  = klass.find(:all, :conditions => {assoc.primary_key_name => model_id})
          
          related.each do |object|
            mirror = mirror_association(model, object, :belongs_to)
            next unless mirror
            
            Primer.bus.publish(:changes, object.primer_identifier + [mirror.name.to_s])
          end
        end
      end
      
      def self.notify_has_many_through_association(model, through_name)
        model.class.reflect_on_all_associations.each do |assoc|
          next unless assoc.macro == :has_many and assoc.options[:through] == through_name
          Primer.bus.publish(:changes, model.primer_identifier + [assoc.name.to_s])
        end
      end
      
      def self.mirror_association(object, related, macro)
        related.class.reflect_on_all_associations.find do |mirror_assoc|
          mirror_assoc.macro == macro and
          mirror_assoc.class_name == object.class.name
        end
      end
    end
    
  end
end

