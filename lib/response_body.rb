module ProtonStream
  
  class ResponseBody
    include EventMachine::Deferrable
    
    attr_accessor :buffer
    
    def initialize(buffer)
      self.buffer = buffer
    end
    
    # Called by Rack to stream bytes 
    #
    def each
      # The callback procs will use the value of p when they are defined      
      p = buffer.head
      
      stream_writer = proc do 
        # wait until the another timer has updated the bytes and moved the head
        until(buffer.head != p) do
          sleep 0.5
        end
        
        # All the listeners get the same data
        bytes = buffer.last_chunk
        
        unless bytes.nil? or bytes.size == 0
          yield bytes
          #yield "head pointer = #{buffer.head}<br/>"
          #puts "Streaming #{bytes.size} bytes  pos=#{buffer.head}"
        end
      end
      
      stream_next = proc do
        # Update the current position
        p = buffer.head
        # Recursively call another deferrable to perpetually stream bytes
        # unless the client disconnects
        EM.defer(stream_writer, stream_next) unless finished
      end
      
      # Kick-off the initial deferrable
      EM.defer(stream_writer, stream_next)
    end
    
    # Called upon client disconnect. Sets a flag to tell the deferrable process
    # to stop running. 
    #
    def close
      finished = true
    end
    
    private
    attr_accessor :finished
  end
  
end
