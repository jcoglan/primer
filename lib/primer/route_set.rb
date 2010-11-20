require 'sinatra'

class Sinatra::Application
  def self.run? ; false ; end
end

module Primer
  class RouteSet
    def initialize(&routes)
      @app = Class.new(Router)
      instance_eval(&routes)
    end
    
    def get(path, &block)
      @app.get(path, &block)
    end
    
    def evaluate(path)
      @app.new(path).evaluate
    end
  end
  
  class Router < Sinatra::Base
    class Request
      attr_reader :path_info
      def initialize(path)
        @path_info = path
      end
    end
    
    # Circumvent the fact that Sinatra::Base.new creates a Rack stack
    def self.new(*args)
      Class.instance_method(:new).bind(self).call(*args)
    end
    
    def initialize(path)
      @request = Request.new(path)
      @original_params = indifferent_hash
    end
    
    def evaluate
      routes = self.class.routes['GET']
      catch(:halt) {
        routes.each do |pattern, keys, conditions, block|
          process_route(pattern, keys, conditions) do
            throw(:halt, instance_eval(&block))
          end
        end
        nil
      }
    end
  end
end

