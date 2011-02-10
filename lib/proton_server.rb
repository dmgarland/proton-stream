require 'rubygems'
require 'sinatra'
require 'mongo'
require 'eventmachine'
require 'active_record'
#require 'sinatra/async'
require 'sinatra/reloader' if development?

require 'lib/audio_queue'
require 'lib/file_audio_queue'
require 'lib/proton-stream/models/track'

class ProtonServer < Sinatra::Base
  # register Sinatra::Async
  
  @@buffer = nil
  @@empty_rack_response = [-1, {}, []].freeze
  @@ogg_mime_type = {'Content-Type' => 'application/ogg'}.freeze
  @@mp3_mime_type = {'Content-Type' => 'audio/mpeg'}.freeze
  @@html_mime_type = {'Content-Type' => 'text/html'}.freeze
  
  # Starts the EventMachine timers
  #
  configure do
    Thread.new do
      until EM.reactor_running?
        sleep 1
      end
      @@buffer = ProtonStream::FileAudioQueue.instance if @@buffer.nil? 

    end
    
    # Establish a connection to the database
    # ActiveRecord::Base.establish_connection(
    # :adapter => 'sqlite3',
    # :database =>  "db/dev.sqlite3"
    # )
  end
  
  get '/play' do

    EM.next_tick do
      request.env['async.callback'].call [200, @@mp3_mime_type, @@buffer]
    end
    
    @@empty_rack_response    
  end
  
end
 