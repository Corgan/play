module Play
  class App < Sinatra::Base
    use Rack::Session::Memcache, :memcache_server => 'localhost:11211', :expire_after => 3600, :namespace => "play"
    
    set :public_folder, "public"
    set :views, "views"
    set :static, true
    set :session_secret, "thisisasecret"
    
    before do
      session[:id] = @env.fetch('HTTP_COOKIE','')[/#{@key}=([^,;]+)/,1] if session[:id].nil?
    end
    
    get '/audio/get' do
      song = Song[:id => params[:id]]
      content_type `file --mime -br "#{song.path}"`.strip.split(';').first
      send_file song.path
    end
    
    get '/' do
      haml :index
    end
    
  end
end