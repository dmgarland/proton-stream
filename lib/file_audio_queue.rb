require 'singleton'

module ProtonStream
  
  class FileAudioQueue
    include EventMachine::Deferrable
    include Singleton
    
    attr_accessor :buffer_file
    
    BLOCK_SIZE = 1024 * 96
    MAX_BUFFER_SIZE = 10 * BLOCK_SIZE
    
    # Adds a periodic timer to the Eventmachine reactor loop and starts 
    # appending bytes to the audio queue
    #
    def initialize
      
      STDOUT.puts "Initialising queue"
      
      self.buffer_file = File.new("/tmp/buffer", "w+")
      @@current_track = Track.next_track
      @@already_read = 0
      
      @@head = 0
      @@tail = 0
      
      append_queue
      
      
      
      # Periodically append more music to the queue      
      EM.add_periodic_timer(5) do
        append_queue
      end
      
      # Every second, read a chunk from the head of the queue
      # so that listening clients can get at it and share the same data
      EM.add_periodic_timer(1) do
        read_chunk
      end
    end
    
    # Gets the next track from Mongo and appends its data to the buffer.
    #
    def append_queue
      if free_space > 0
        puts "reading #{@@current_track} into buffer"
        @db = Mongo::Connection.new.db("mostrated")
        @fs = Mongo::GridFileSystem.new(@db) 
        
        track = @fs.open(@@current_track, "r")     
        
        if track.file_length > free_space
          # The file is too big to read into the buffer, so read up until
          # the free space is used
          STDOUT.puts "#{free_blocks} free blocks"
          free_blocks.times {
            STDOUT.puts "Writing #{BLOCK_SIZE} from track pos #{track.tell} to buffer pos #{@@tail}"
            if @@already_read < track.file_length
              track.seek @@already_read
              buffer_file.seek @@tail 
              begin
                bytes = track.read(BLOCK_SIZE)
              rescue Exception => e
                STDOUT.puts "fuckup : #{e}"
              end
                
              buffer_file.write bytes     
              
              # If we've reached the end of the buffer, wrap around to the front
              if buffer_file.tell >= MAX_BUFFER_SIZE
                @@tail = 0
              else
                @@tail += BLOCK_SIZE
              end
              
              @@already_read += BLOCK_SIZE
            else
              # We've read until until the end of a track, time for another one
              @@current_track = Track.next_track
              @@already_read = 0
            end
          }
        else
          # We can completely read the file into the buffer
          buffer_file << track.read
          @@already_read = 0
        end
        
        
        puts "buffer size: #{File.size(buffer_file)} / #{free_space} free"
        
      end
    end
    
    def read_chunk
      STDOUT.puts("Reading #{BLOCK_SIZE} bytes from offset #{@@head}")
      
      # Read a block relative to the head pointer offset
      @@last_chunk = File.read(buffer_file.path, BLOCK_SIZE, @@head)
      @@head += BLOCK_SIZE
      
      # If we've read to the end, loop around to the start
      if @@head > File.size(buffer_file)
        @@head = 0
      end        
    end
    
    def each
      # The callback procs will use the value of p when they are defined      
      p = @@head
      
      stream_writer = proc do 
        STDOUT.puts "stream writer #{p}"
        
        # wait until the another timer has updated the bytes and moved the head
        until(@@head != p) do
          sleep 0.5
        end
        
        # All the listeners get the same data
        bytes = @@last_chunk
        
        unless bytes.nil? or bytes.size == 0
          yield bytes
          #yield "head pointer = #{@@head}<br/>"
          STDOUT.puts "Wrote #{bytes.size} bytes  pos=#{@@head}"
        else
          STDOUT.puts "no bytes pos=#{@@head}"
        end
      end
      
      end_of_write_callback = proc do
        #STDOUT.puts "end of write callbcak"
        # Update the current position
        p = @@head
        EM.defer(stream_writer, end_of_write_callback)
      end
      
      EM.defer(stream_writer, end_of_write_callback)
    end
    
    
    
    def free_space
      buffer_file_size = File.size(buffer_file)
      free_space = 0
      
      if buffer_file_size < MAX_BUFFER_SIZE
        # We haven't yet filled the buffer
        free_space = MAX_BUFFER_SIZE - buffer_file_size
      else
        # The free space is the difference between the tail and the head
        
        if @@head > @@tail
          free_space = @@head - @@tail
        elsif @@head == @@tail
          free_space = 0
        else
          free_space = (MAX_BUFFER_SIZE - @@tail) + @@head
        end
      end
      
      STDOUT.puts "free space = #{free_space} tail = #{@@tail} head = #{@@head}"
      return free_space
    end
    
    def free_blocks
      free_space / BLOCK_SIZE
    end
  end
  
end
