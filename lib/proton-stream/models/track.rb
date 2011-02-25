class Track
  include MongoMapper::Document
  plugin Joint
  
  key :title,     String
  key :random,    Integer  
  attachment :file
  timestamps!
  
  def self.next_track(current_id = nil)
    # Random
    random = rand(100000).to_i
    track = Track.where(:random.gt => random, :_id.ne => current_id).sort(:random).first
    track = Track.where(:random.lt => random, :_id.ne => current_id).sort(:random).first if track.nil?
    return track
  end
  
  def to_json(*a)
    { 
      :title => title 
    }.to_json(*a)
  end
  
end
