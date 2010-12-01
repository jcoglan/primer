module Primer
  module Lazyness
    
    def self.included(klass)
      klass.extend(Macros)
      if defined?(ActiveRecord) and klass < ActiveRecord::Base
        klass.lazy_patch(:find, :all, :first, :last, :method_missing)
      end
    end
    
    module Macros
      def lazy_patch(*method_names)
        method_names.each do |method_name|
          instance_eval <<-RUBY
            alias :eager_#{method_name} :#{method_name}
            def #{method_name}(*args, &block)
              Primer::Lazyness::Proxy.new(self, primary_key, :eager_#{method_name}, args, block)
            end
          RUBY
        end
      end
    end
    
    class Proxy
      methods = instance_methods.map { |m| m.to_s } - %w[object_id __id__ __send__]
      methods.each { |m| undef_method m }
      
      def initialize(real_class, primary_key, load_method, arguments, block)
        @real_class  = real_class
        @primary_key = primary_key
        @load_method = load_method
        @arguments   = arguments
        @block       = block
      end
      
      def method_missing(method_name, *args, &block)
        if @load_method.to_s == 'eager_method_missing'
          if method_name.to_s == @arguments.first.to_s.gsub(/^find_by_/, '')
            return @arguments[1]
          else
            return __subject__.__send__(method_name, *args, &block)
          end
        end
        
        if method_name.to_s == @primary_key.to_s
          return @arguments.first
        end
        
        __subject__.__send__(method_name, *args, &block)
      end
      
    private
      
      def __subject__
        @__subject__ ||= @real_class.__send__(@load_method, *@arguments, &@block)
      end
    end
    
  end
end

