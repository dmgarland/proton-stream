require 'rubygems'
require 'sinatra'
require 'eventmachine'

class EventStream
  include EventMachine::Deferrable
  def each
    count = 0
    bitrate = 1024 * 160
    timer = EventMachine::PeriodicTimer.new(1) do
      bytes = File.read("fl.ogg", bitrate, count)
      if bytes
        yield bytes
        count += bitrate
        STDOUT.puts "Wrote #{bytes.size} bytes"
      end
    end
    errback { timer.cancel }
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

