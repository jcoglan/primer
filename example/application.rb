require 'rubygems'
require 'sinatra'
require 'active_record'

class Application < Sinatra::Base
  ROOT = File.expand_path(File.dirname(__FILE__))
  
  require ROOT + '/../lib/primer'
  Primer.cache = Primer::Cache::Redis.new
  Primer.real_time = true
  
  require ROOT + '/models/connection'
  require ROOT + '/models/blog_post'
  
  # Set up cache generators
  Primer.cache.routes = Primer::RouteSet.new do
    get('/posts/:id/author') { BlogPost.find(params[:id]).author }
  end
  
  # Configure Sinatra
  set :views, ROOT + '/views'
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

