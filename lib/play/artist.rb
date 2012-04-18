module Play
  class Artist < Sequel::Model
    one_to_many :songs
    many_to_many :albums
    def enqueue(session_id)
      songs.collect do |song|
        song.enqueue(session_id)
        song
      end
    end
  end
end