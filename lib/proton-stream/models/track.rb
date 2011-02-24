class Track
  include MongoMapper::Document
  plugin Joint
  
  key :title,     String
  key :random,    Integer  
  attachment :file
  timestamps!
  
  def self.next_track

    # Random
    # random = rand(100000)
    # track = Track.first(:conditions => { :random => { "$gt" => random }})
    # track = Track.first(:conditions => { :random => { "$lt" => random }}) if track.nil?
    # 
    # return track
    #Track.create(:title => "Bach", :file => File.new('/home/daniel/Music/grade 8/PF_G8_A1_J_S_Bach_Capriccio_160bpm.mp3'))
    Track.first   
  end
  
end
