require 'rubygems'
require 'sinatra'
require 'eventmachine'

class EventStream
  include EventMachine::Deferrable
  def each
    count = 0
    bitrate = 1024 * 160
    stream_writer = proc do 
      bytes = File.read("fl.ogg", bitrate, count)
      sleep 0.5
      if bytes
        yield bytes
        count += bitrate
        STDOUT.puts "Wrote #{bytes.size} bytes"
      end
    end
    
    end_of_write_callback = proc do
      EM.defer(stream_writer, end_of_write_callback)
    end
      
    EM.defer(stream_writer, end_of_write_callback)
  
    
  end
end

get '/play' do
  #audio/mpeg
  EventMachine.next_tick do
    request.env['async.callback'].call [
    200, {'Content-Type' => 'application/ogg'},
      EventStream.new ]
  end
  [-1, {}, []]
  STDOUT.puts "qutting play"
end

