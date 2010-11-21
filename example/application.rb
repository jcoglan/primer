require 'rubygems'
require 'sinatra'

class Application < Sinatra::Base
  ROOT = File.expand_path(File.dirname(__FILE__))
  
  require ROOT + '/environment'
  
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

