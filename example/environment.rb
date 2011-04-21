dir = File.expand_path(File.dirname(__FILE__))

# Load gems: ActiveRecord and Primer
require 'rubygems'
require 'active_record'
require dir + '/../lib/primer'

# Load database config and models
require dir + '/db/connection'
require dir + '/models/post'
require dir + '/models/comment'

# Configure Primer with a Redis cache and AMQP bus
Primer.cache = Primer::Cache::Redis.new
Primer.bus   = Primer::Bus::AMQP.new(:queue => 'blog_changes')

# Enable real-time page updates
Primer.real_time = true
Primer::RealTime.bayeux_server = 'http://0.0.0.0:9292'
Primer::RealTime.password = 'omg_rofl_scale'

# Set up cache generation routes
Primer.cache.routes do
  get '/posts/:id/date' do
    post = Post.find(params[:id])
    post.created_at.strftime('%A %e %B %Y')
  end
  
  get '/posts/:id/title' do
    post = Post.find(params[:id])
    post.title.upcase
  end
  
  get '/posts/:id/comments' do
    @post = Post.find(params[:id])
    ERB.new(File.read(dir + '/views/comments.erb')).result(binding)
  end
end

