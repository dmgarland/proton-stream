require 'singleton'

module ProtonStream
  
  class FileAudioQueue
    include Singleton
    
    attr_accessor :buffer_file
    
    BIT_RATE = 80
    BLOCK_SIZE = 1024 * BIT_RATE
    MAX_BUFFER_SIZE = 10 * BLOCK_SIZE
    
    # Adds a periodic timer to the Eventmachine reactor loop and starts 
    # appending bytes to the audio queue
    #
    def initialize
      self.buffer_file = File.new("/tmp/buffer", "w+")
      @@current_track = Track.next_track
      @@already_read = 0      
      @@head = 0
      @@tail = 0
      
      # Fill the buffer to start off with
      append_queue
      
      # Periodically append more music to the queue      
      EM.add_periodic_timer(3) do
        append_queue
      end
      
      # Every second, read a chunk from the head of the queue
      # so that listening clients can get at it and share the same data
      EM.add_periodic_timer(1) do
        read_chunk
      end
      
      puts "Initialised queue: buffer max #{MAX_BUFFER_SIZE} #{BIT_RATE}kbs"
    end
    
    def head
      @@head
    end
    
    def last_chunk
      @@last_chunk
    end
    
    def current_track
      @@current_track
    end
    
    # ==========================================================================
    private
    
    # Gets the next track from Mongo and appends its data to the buffer.
    #
    def append_queue
      if free_space > 0        
        free_blocks.times {           
          if @@already_read < @@current_track.file.size
            buffer_block @@current_track
          else
            # We've finished this track, on to the next one
            load_next_track
            return
          end
        }
      else
        #puts "Buffer full"        
      end
    end
    
    # Read a chunk of bytes from the head of the buffer and store it in a 
    # class variable, so that every listening client can access the same data
    # without manipulting the pointers
    #
    def read_chunk
      #puts("Reading #{BLOCK_SIZE} bytes from offset #{@@head}")
      
      # Read a block relative to the head pointer offset
      @@last_chunk = File.read(buffer_file.path, BLOCK_SIZE, @@head)
      @@head += BLOCK_SIZE
      
      # If we've read to the end, loop around to the start
      if @@head >= File.size(buffer_file)
        @@head = 0
      end        
    end
    
    # Writes a block from the mongo track handle to the buffer, allowing for
    # wrap-arounds if we've hit the end of the buffer.
    #
    def buffer_block(track)
      begin
        # Seek to the relevant points in the track
        track.file.seek @@already_read
        
        # Seek to the tail of the buffer
        buffer_file.seek @@tail       
        # Read a block
        bytes = track.file.read(BLOCK_SIZE)
        
        # If we've reached the end of a track, and don't have enough bytes to fill
        # up a block, we need to pad the rest of the block with zeros to ensure
        # that whatever was previsouly in the block gets wiped, otherwise we'll
        # hear memories from the previous audio in the queue...
        if bytes.size < BLOCK_SIZE        
          padding = "\000" * (BLOCK_SIZE - bytes.size)
          bytes.concat(padding)
        end
        
        # Write the bytes to the end of the queue
        #puts "Writing #{BLOCK_SIZE} from track pos #{@@already_read} to buffer pos #{@@tail}"
        buffer_file.write bytes
        
        # If we've reached the end of the buffer, wrap around to the front
        if buffer_file.tell >= MAX_BUFFER_SIZE
          @@tail = 0
        else
          @@tail += BLOCK_SIZE
        end
        
        # Remember how far into the track we have already read onto the queue
        @@already_read += BLOCK_SIZE
        
      rescue Exception => e
        puts e
        # So somethings wrong with that track, go find another one...
        buffer_block load_next_track
      end
    end
    
    # Calculates the number of bytes in the buffer that can be safely written
    # without over-writing queued data
    #
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
      
      return free_space
    end   
    
    # Loads the next track and updates pointers
    def load_next_track
      @@already_read = 0
      @@current_track = Track.next_track(@@current_track._id)      
    end
    
    # Returns the number of blocks there are based on the bit rate
    def free_blocks
      free_space / BLOCK_SIZE
    end
    
  end
  
end
