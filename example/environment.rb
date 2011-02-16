dir = File.expand_path(File.dirname(__FILE__))

# Load gems: ActiveRecord and Primer
require 'rubygems'
require 'active_record'
require dir + '/../lib/primer'

# Load database config and models
require dir + '/models/connection'
require dir + '/models/blog_post'

# Configure Primer with a Redis cache and AMQP bus
Primer.cache = Primer::Cache::Redis.new
Primer.bus   = Primer::Bus::AMQP.new(:queue => 'blog_changes')
Primer.ssi   = true

# Enable real-time page updates
Primer.real_time = true
Primer::RealTime.bayeux_server = 'http://0.0.0.0:9292'
Primer::RealTime.password = 'omg_rofl_scale'

# Set up cache generation routes
Primer.cache.routes do
  get '/posts/:id/date' do
    BlogPost.find(params[:id]).created_at.strftime('%A %e %B %Y')
  end
  
  get '/posts/:id/title' do
    BlogPost.find(params[:id]).title.upcase
  end
end

