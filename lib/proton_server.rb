require 'sinatra'
require 'mongo'
require 'eventmachine'
require 'sinatra/reloader' if development?

require 'lib/audio_queue'
require 'lib/file_audio_queue'
require 'lib/response_body'
require 'lib/proton-stream/models/track'

class ProtonServer < Sinatra::Base
  
  include ProtonStream
  
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
      
      # Create a singleton instance of a file-backed audio queue
      # which automatically starts buffering content
      @@buffer = FileAudioQueue.instance if @@buffer.nil?
    end
  end
  
  get '/play' do

    EM.next_tick do
      request.env['async.callback'].call [200, @@mp3_mime_type, ResponseBody.new]
    end
    
    @@empty_rack_response    
  end
  
end
 