require 'sinatra/base'
require 'sinatra/reloader'
require 'eventmachine'
require 'mongo'
require 'mongo_mapper'
require 'joint'

require 'lib/file_audio_queue'
require 'lib/response_body'
require 'lib/proton-stream/models/track'

class ProtonServer < Sinatra::Base
  
  include ProtonStream
  
  @@buffer = nil
  @@keep_alive = [-1, {}, []].freeze
  @@ogg_mime_type = {'Content-Type' => 'application/ogg'}.freeze
  @@mp3_mime_type = {'Content-Type' => 'audio/mpeg'}.freeze
  @@html_mime_type = {'Content-Type' => 'text/html'}.freeze 
  
  # Reload app classes and templates in development
  configure(:development) do
    require 'ruby-debug'
    register Sinatra::Reloader    
  end
  
  # Starts the EventMachine timers
  #
  configure do
    Thread.new do
      until EM.reactor_running?
        sleep 1
      end
      
      # Mongo DB
      MongoMapper.database = "mostrated_#{Sinatra::Application.environment.to_s}"
      # Track.ensureIndex("random")
      # Track.ensureIndex("_id")
      
      # Create a singleton instance of a file-backed audio queue
      # which automatically starts buffering content
      @@buffer = FileAudioQueue.instance if @@buffer.nil?
    end
  end
  
  get '/play.mp3' do
    
    EM.next_tick do
      request.env['async.callback'].call [200, @@mp3_mime_type, ResponseBody.new]
    end
    
    @@keep_alive    
  end
  
  get '/current_track.json' do
    content_type :json
    @@buffer.current_track.to_json
  end
  
end
