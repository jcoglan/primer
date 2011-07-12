module Primer
  class Worker
    
    class ActiveRecordAgent < Agent
      topic :active_record
      
      def on_message(message)
        event, class_name, attributes, changes = *message
        model = class_name.constantize.new(attributes)
        
        model.instance_eval do
          @attributes = attributes
          @changed_attributes = changes if changes
        end
        
        case event
          when 'create'
            notify_belongs_to_associations(model)
          when 'update'
            notify_attributes(model, model.changes)
          when 'destroy'
            notify_attributes(model, model.attributes)
            notify_has_many_associations(model)
        end
      end
      
      def notify_attributes(model, fields)
        foreign_keys = model.class.primer_foreign_key_mappings
        
        fields.each do |attribute, value|
          Primer.bus.publish(:changes, model.primer_identifier + [attribute.to_s])
          
          next unless assoc = foreign_keys[attribute.to_s]
          Primer.bus.publish(:changes, model.primer_identifier + [assoc.to_s])
          notify_belongs_to_association(model, assoc, value)
        end
      end
      
      def notify_belongs_to_associations(model)
        model.class.reflect_on_all_associations.each do |assoc|
          next unless assoc.macro == :belongs_to
          notify_belongs_to_association(model, assoc.name)
        end
      end
      
      def notify_belongs_to_association(model, assoc_name, change = nil)
        assoc = model.class.reflect_on_association(assoc_name)
        owner_class = assoc.class_name.constantize
        
        mirror = mirror_association(model.class, owner_class, :has_many)
        
        if owner = model.__send__(assoc_name)
          Primer.bus.publish(:changes, owner.primer_identifier + [mirror.name.to_s])
          notify_has_many_through_association(owner, mirror.name)
        end
        
        return unless Array === change and change.first.any?
        old_id = change.first.first
        previous = owner_class.find(:first, :conditions => {owner_class.primary_key => old_id})
        return unless previous
        
        Primer.bus.publish(:changes, previous.primer_identifier + [mirror.name.to_s])
        notify_has_many_through_association(previous, mirror.name)
      end
      
      def notify_has_many_associations(model)
        model.class.reflect_on_all_associations.each do |assoc|
          next unless assoc.macro == :has_many
          next if assoc.options[:dependent] == :destroy
          
          model_id = model.__send__(model.class.primary_key)
          klass    = assoc.class_name.constantize
          related  = klass.find(:all, :conditions => {assoc.primary_key_name => model_id})
          
          related.each do |object|
            mirror = mirror_association(model.class, object.class, :belongs_to)
            next unless mirror
            
            Primer.bus.publish(:changes, object.primer_identifier + [mirror.name.to_s])
          end
        end
      end
      
      def notify_has_many_through_association(model, through_name)
        model.class.reflect_on_all_associations.each do |assoc|
          next unless assoc.macro == :has_many
          
          if assoc.options[:through] == through_name
            Primer.bus.publish(:changes, model.primer_identifier + [assoc.name.to_s])
          end
          
          assoc.class_name.constantize.reflect_on_all_associations.each do |secondary|
            next unless secondary.macro == :has_many and secondary.options[:through] and
                        secondary.source_reflection.active_record == model.class and
                        secondary.source_reflection.name == through_name
            
            model.__send__(assoc.name).each do |related|
              Primer.bus.publish(:changes, related.primer_identifier + [secondary.name.to_s])
            end
          end
        end
      end
      
      def mirror_association(object_class, related_class, macro)
        long_name  = object_class.name
        short_name = long_name.split('::').last
        
        related_class.reflect_on_all_associations.find do |mirror_assoc|
          mirror_assoc.macro == macro and
          [long_name, short_name].include?(mirror_assoc.class_name)
        end
      end
    end
    
  end
end

