class Track
  
  #attr_accessor :bytes_read
  @@count = 0
  
  def self.next_track
     
    
    # Track selection will be more compilcated than this...
    file = ""
    if @@count % 2 == 0
      file = "bach.mp3"      
    else
      file = "mindfield.mp3"
    end
    
    @@count += 1
    
    #STDOUT.puts file + " #{@@count}"
    return file
    
    
  end
  
end
