require 'pp'

module Play
  class QueuedItem < Sequel::Model
    many_to_one :song
  end
  
  class Queue
    def self.next(session_id)
      queuedItem = QueuedItem.where(:session_id => session_id).first
      queuedItem.delete if !queuedItem.nil?
      queuedItem = QueuedItem.where(:session_id => session_id).first
      if queuedItem.nil?
        song = Song.all.sample
        item = QueuedItem.create(:session_id => session_id)
        item.song = song
        item.save
      else  
        song = queuedItem.song
      end
      song
    end
  end
end