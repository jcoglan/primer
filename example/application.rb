require 'rubygems'
require 'sinatra'
require 'active_record'

class Application < Sinatra::Base
  ROOT = File.expand_path(File.dirname(__FILE__))
  
  # Load Primer and models
  require ROOT + '/../lib/primer'
  require ROOT + '/models/connection'
  require ROOT + '/models/blog_post'
  Primer.cache = Primer::Cache::Redis.new
  
  # Configure Sinatra
  set :views, ROOT + '/views'
  helpers { include Primer::Helpers::ERB }
  
  # Make the routes
  
  get '/' do
    @posts = BlogPost.all
    erb :index
  end
  
  get '/posts/:id' do
    @post = BlogPost.find(params[:id])
    erb :show
  end
end

