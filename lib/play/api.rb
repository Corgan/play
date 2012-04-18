module Play
  class App < Sinatra::Base
    before '/api/*' do
      content_type :json
    end
    
    get "/api/playing" do
      item = QueuedItem.where(:session_id => session[:id]).first
      if(item)
        music_response({:song => item.song, :album => item.song.album, :artist => item.song.artist}).to_json
      else
        redirect '/api/next'
      end
    end

    get "/api/next" do
      song = Queue.next(session[:id])
      if song
        music_response({:song => song, :album => song.album, :artist => song.artist}).to_json
      else
        error_response "There's a problem playing the next song."
      end
    end
    
    get "/api/queue" do
      items = QueuedItem.where(:session_id => session[:id]).all
      items.shift
      {:songs => items.collect { |item| music_response({:song => item.song, :album => item.song.album, :artist => item.song.artist}).merge({:queue_id => item.id}) } }.to_json
    end
    
    get "/api/remove" do
      q = QueuedItem.where(:session_id => session[:id], :id => params[:id]).first
      if !q.nil? && q.delete
        { :success => true}.to_json
      else
        error_response "An error occured"
      end
    end

    get "/api/clear" do 
      if QueuedItem.where(:session_id => session[:id]).delete
        { :success => true }.to_json
      else
        error_response "Wasn't able to clear the queue"
      end
    end


    get "/api/song_info" do
      song = Song[:id => params[:id]]
      if song
        music_response({:song => song, :album => song.album, :artist => song.artist}).to_json
      else
        error_response "No song by that ID"
      end
    end


    get "/api/artists" do
      a = Artist.all
      {:artists => a.collect { |artist| music_response({:artist => artist}) } }.to_json
    end

    get "/api/add_artist" do
      artist = Artist[:id => params[:id]]
      if artist
        {:songs => artist.enqueue(session[:id]).collect { |song| music_response({:song => song, :album => song.album, :artist => song.artist}) }}.to_json
      else
        error_response("Sorry, but we couldn't find that artist.")
      end
    end
    
    
    
    
    get "/api/albums" do
      if(params[:artist]) then
        artist = Artist[:id => params[:artist]]
        if(artist)
          {:albums => artist.albums_dataset.distinct.collect { |album| music_response({:album => album, :artist => artist}) } }.to_json
        else
          error_response "Artist not found"
        end
      else  
        {:albums => Album.all.collect { |album| music_response({:album => album}) } }.to_json
      end
    end

    get "/api/add_album" do
      album = Album[:id => params[:id]]
      if album
        {:songs => album.enqueue(session[:id]).collect { |song| music_response({:song => song, :album => song.album, :artist => song.artist}) }}.to_json
      else
        error_response("Sorry, but we couldn't find that album.")
      end
    end
    
    
    
    get "/api/songs" do
      if(params[:artist] && params[:album]) then
        songs = Song.filter(:album_id => params[:album], :artist_id => params[:artist]).all
        if(songs)
          {:songs => songs.collect { |song| music_response({:song => song, :album => song.album, :artist => song.artist}) } }.to_json
        else
          error_response "No Songs."
        end
      elsif(params[:artist]) then
        songs = Song.filter(:artist_id => params[:artist]).all
        if(songs)
          {:songs => songs.collect { |song| music_response({:song => song, :album => song.album, :artist => song.artist}) } }.to_json
        else
          error_response "Artist not found"
        end
      elsif(params[:album]) then
        songs = Song.filter(:album_id => params[:album]).all
        if(songs)
          {:songs => songs.collect { |song| music_response({:song => song, :album => song.album, :artist => song.artist}) } }.to_json
        else
          error_response "Album not found"
        end
      end
    end

    get "/api/add_song" do
      song = Song[:id => params[:id]]
      if song
        song.enqueue(session[:id])
        music_response({:song => song, :album => song.album, :artist => song.artist}).to_json
      else
        error_response("Sorry, but we couldn't find that song.")
      end
    end
    
    

    def error_response(msg)
      { :error => msg }.to_json
    end

    def music_response(args)
      resp = {}
      resp[:song]   = { :id => args[:song].id,   :name => args[:song].name }   if !args[:song].nil?
      resp[:artist] = { :id => args[:artist].id, :name => args[:artist].name } if !args[:artist].nil?
      resp[:album]  = { :id => args[:album].id,  :name => args[:album].name }  if !args[:album].nil?
      resp
    end
    
  end
end