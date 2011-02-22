class Track < ActiveRecord::Base
  
  #attr_accessor :bytes_read
  @@count = 0
  
  def self.next_track
     
    
    # Track selection will be more compilcated than this...
    file = ""
    if @@count % 2 == 0
      file = "/home/daniel/Music/grade 8/PF_G8_A1_J_S_Bach_Capriccio.mp3"      
    else
      file = "mindfield.mp3"
    end
    
    @@count += 1
    
    STDOUT.puts file + " #{@@count}"
    return file
    
    
  end
  
end
