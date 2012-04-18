class CreateSchema < ActiveRecord::Migration
  def self.up
    create_table :songs do |t|
      t.string  :title
      t.string  :path
      t.integer :artist_id
      t.integer :album_id
    end

    create_table :artists do |t|
      t.string  :name
    end

    create_table :albums do |t|
      t.string  :name
      t.integer :artist_id
    end

    create_table :queued_items do |t|
      t.integer :song_id
      t.string  :session_id
      t.timestamps
    end
  end
 
  def self.down
    drop_table :songs
    drop_table :artists
    drop_table :albums
    drop_table :queued_items
  end
end
