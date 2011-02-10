class Track < ActiveRecord::Base
  
  def self.read_next_track(buffer)
    puts "reading into buffer"
    @db = Mongo::Connection.new.db("mostrated")
    @fs = Mongo::GridFileSystem.new(@db)  
        
    track = @fs.open("mindfield.mp3", "r") { |f|
      buffer << f.read      
    }
    
    puts "buffer size: #{File.size(buffer)}"
  end
  
end
