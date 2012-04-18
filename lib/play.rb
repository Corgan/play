$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'sinatra/base'
require 'yajl'
require 'active_record'
require 'audioinfo'
require 'eventmachine'
require 'pp'
require 'haml'
require 'sequel'
require 'json'

module Play
  DB = Sequel.sqlite('db/database.db')
  
  
  DB.create_table?(:artists) do
    primary_key :id
    String :name
  end
  
  DB.create_table?(:albums) do
    primary_key :id
    String :name
    foreign_key :artist_id, :artists
  end
  
  DB.create_table?(:albums_artists) do
    primary_key :id
    foreign_key :album_id, :albums
    foreign_key :artist_id, :artists
  end
  
  DB.create_table?(:songs) do
    primary_key :id
    String :name
    String :path
    foreign_key :artist_id, :artists
    foreign_key :album_id, :albums
  end

  DB.create_table?(:queued_items) do
    primary_key :id
    foreign_key :song_id, :songs
    String :session_id
  end
  
  def self.path=(path)
    @path = path
  end
  
  def self.path
    config['path']
  end

  def self.config_path
    "config/play.yml"
  end

  def self.config
    YAML::load(File.open(config_path))
  end
end

require 'play/app'
require 'play/api'
require 'play/song'
require 'play/album'
require 'play/artist'
require 'play/queue'
require 'play/library'