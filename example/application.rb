require 'rubygems'
require 'sinatra'
require 'active_record'

class Application < Sinatra::Base
  ROOT = File.expand_path(File.dirname(__FILE__))
  
  require ROOT + '/../lib/primer'
  Primer.cache = Primer::Cache::Redis.new
  
  Primer.real_time = true
  Primer::RealTime.bayeux_server = 'http://0.0.0.0:9292'
  
  require ROOT + '/models/connection'
  require ROOT + '/models/blog_post'
  
  # Set up cache generators
  Primer.cache.routes do
    get('/posts/:id/title') { BlogPost.find(params[:id]).title.upcase }
  end
  
  # Configure Sinatra
  set :reload_templates, true
  set :static, true
  set :public, ROOT + '/public'
  set :views,  ROOT + '/views'
  helpers { include Primer::Helpers::ERB }
  
  get '/' do
    @posts = BlogPost.all
    erb :index
  end
  
  get '/posts/:id' do
    @post = BlogPost.find(params[:id])
    erb :show
  end
end

