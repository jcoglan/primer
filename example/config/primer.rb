require Application::ROOT + '/../lib/primer'
Primer.cache = Primer::Cache::Redis.new

Primer.real_time = true
Primer::RealTime.bayeux_server = 'http://0.0.0.0:9292'
Primer::RealTime.password = 'omg_rofl_scale'

Primer.cache.routes do
  get '/posts/:id/date' do
    BlogPost.find(params[:id]).created_at.strftime('%A %e %B %Y')
  end
  
  get '/posts/:id/title' do
    BlogPost.find(params[:id]).title.upcase
  end
end

