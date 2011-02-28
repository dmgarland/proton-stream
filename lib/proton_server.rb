require 'sinatra/base'
require 'sinatra/reloader'
require 'eventmachine'
require 'mongo'
require 'mongo_mapper'
require 'joint'
require 'erb'
require File.dirname(__FILE__) +  '/ext/partials'

require 'lib/file_audio_queue'
require 'lib/response_body'
require 'lib/proton-stream/models/track'

class ProtonServer < Sinatra::Base
  
  include ProtonStream
  
  @@buffers = {}
  @@keep_alive = [-1, {}, []].freeze
  @@ogg_mime_type = {'Content-Type' => 'application/ogg'}.freeze
  @@mp3_mime_type = {'Content-Type' => 'audio/mpeg'}.freeze
  @@html_mime_type = {'Content-Type' => 'text/html'}.freeze
  
  set :views, File.dirname(__FILE__) + '/proton-stream/views'
  
  # Register helpers
  #
  helpers do
    include Sinatra::Partials
    alias_method :h, :escape_html
  end
  
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
      queues = YAML::load_file('config/queues.yml')
      for q in queues do 
        @@buffers[q] = FileAudioQueue.new if @@buffers[q].nil?
      end
    end
  end
  
  get '/:queue/play.mp3' do    
    buffer = @@buffers[params[:queue]]    
    if buffer    
      EM.next_tick do
        request.env['async.callback'].call [200, @@mp3_mime_type, ResponseBody.new(buffer)]
      end      
      @@keep_alive
    else
      404
    end      
  end
  
  get '/:queue/current_track.json' do
    buffer = @@buffers[params[:queue]]    
    if buffer
      content_type :json
      buffer.current_track.to_json
    else
      404
    end
  end

end
