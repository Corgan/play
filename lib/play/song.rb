module Play
  class Song < Sequel::Model
    many_to_one :artist
    many_to_one :album
    one_to_many :queued_items

    def enqueue(session_id)
      item = QueuedItem.create(:session_id => session_id)
      item.song = self
      item.save
      item.song
    end
  end
end