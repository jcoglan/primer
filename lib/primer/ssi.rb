module Primer
  class SSI
    
    SCRIPT_PATH   = /^\/primer_cache/
    TYPE_TEXT     = {'Content-Type' => 'text/plain'}
    
    def initialize(app)
      @app = app
    end
    
    def call(env)
      path = Rack::Request.new(env).path_info
      return @app.call(env) unless path =~ SCRIPT_PATH
      cache_key = path.gsub(SCRIPT_PATH, '')
      [200, TYPE_TEXT, [Primer.cache.compute(cache_key)]]
    end
    
  end
end

