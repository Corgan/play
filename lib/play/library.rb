module Play
  class Library
    def self.fs_songs(path)
      `find -L "#{path}" -type f ! -path '#{path}/.*' ! -name '.*'`.split("\n")
    end
    
    def self.import_songs(path=Play.path)
      fs_songs(path).each do |path|
        import_song(path)
      end
    end
    
    def self.prune_songs
      Song.all.each do |song|
        begin
          fs_get_artist_and_title_and_album(song.path)
        rescue AudioInfoError
          print "'#{song.path}' is bad, removing from database.\n"
          song.destroy
        end
      end
    end
    
    def self.import_song(path)
      artist_name, song_name, album_name = fs_get_artist_and_title_and_album(path)
      return if artist_name.empty? or song_name.empty?
      artist = Artist.find_or_create(:name => artist_name)
      album = Album.where(:name => album_name).first ||
              Album.create(:name => album_name)
      
      album.add_artist(artist)
      album.save
      
      song = Song.where(:path => path).first

      if !song
        Song.create(:path => path,
                    :artist => artist,
                    :album => album,
                    :name => song_name)
        puts "Importing #{artist_name} - #{song_name}"
      end
    rescue AudioInfoError
    end
    
    def self.fs_get_artist_and_title_and_album(path)
      AudioInfo.open(path) do |info|
        return info.artist,
               info.title,
               info.album
      end
    end
  end
end