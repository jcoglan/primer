require 'rubygems'
require 'sinatra'
require 'active_record'
require 'fileutils'

class Application < Sinatra::Base
  ROOT = File.expand_path(File.dirname(__FILE__))
  
  # Connect to the database
  FileUtils.mkdir_p(ROOT + '/db')
  dbfile = ROOT + '/db/blog.sqlite3'
  ActiveRecord::Base.establish_connection(:adapter  => 'sqlite3', :database => dbfile)
  
  # Load Primer and models
  require ROOT + '/../lib/primer'
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

