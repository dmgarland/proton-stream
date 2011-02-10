require 'singleton'

module ProtonStream
  
  class AudioQueue < StringIO
    include EventMachine::Deferrable
    include Singleton
    
    
    MAX_BUFFER_SIZE = 10240
    BLOCK_SIZE = 1024 * 96
    
    # Adds a periodic timer to the Eventmachine reactor loop and starts 
    # appending bytes to the audio queue
    #
    def initialize
      super("", "w+")
      
      STDOUT.puts "Initialising queue"
      
      append_queue
      @@head = 0
      rewind
      
      EM.add_periodic_timer(2) do
        append_queue
      end
      
      EM.add_periodic_timer(1) do
        read_chunk
      end
    end
    
    # Gets the next track from Mongo and appends its data to the buffer.
    #
    def append_queue
      if size < MAX_BUFFER_SIZE
        Track.read_next_track(self)
      end
    end
    
    def read_chunk
      pos = @@head
      begin
        unless eof?
          @@last_chunk = read(BLOCK_SIZE)
          @@head += BLOCK_SIZE
        else
          STDOUT.puts "Reached EOF"
        end
      rescue IOError => e
        STDOUT.puts e
        STDOUT.puts "pos = #{pos}"
        EM.stop
      end
      # if @@last_chunk
        # STDOUT.puts "read #{@@last_chunk.size} bytes #{@@head}"
      # else
        # STDOUT.puts "no bytes on read head = #{@@head} pos = #{pos}"
      # end
        
    end
    
    def each
      
      # timer = EventMachine::PeriodicTimer.new(1) do
      # bytes = read(BLOCK_SIZE)
      # 
      # unless bytes.nil? or bytes.size == 0
      # yield bytes
      # STDOUT.puts "Wrote #{bytes.size} bytes  pos=#{pos}"
      # else
      # STDOUT.puts "no bytes pos=#{pos}"
      # end
      # 
      # end
      # errback { timer.cancel }
      
      p = @@head
      
      stream_writer = proc do 
        STDOUT.puts "stream writer #{p}"
        
        # wait until the other timer has updated the bytes
        until(@@head != p) do
          sleep 1
          #STDOUT.puts "head #{@@head} != #{p}"
        end
        
        bytes = @@last_chunk
        
        unless bytes.nil? or bytes.size == 0
          yield bytes
          STDOUT.puts "Wrote #{bytes.size} bytes  pos=#{@@head}"
        else
          STDOUT.puts "no bytes pos=#{@@head}"
        end
      end
      
      end_of_write_callback = proc do
        STDOUT.puts "end of write callbcak"
        p = @@head
        EM.defer(stream_writer, end_of_write_callback)
      end
      
      EM.defer(stream_writer, end_of_write_callback)
    end
    
  end
  
end
