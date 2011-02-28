class Track
  include MongoMapper::Document
  plugin Joint
  
  key :uuid,      String
  key :title,     String
  key :random,    Integer, :default => Proc.new { rand(100000) }
  attachment :file
  timestamps!
  
  attr_accessor :validate_file
  attr_accessor :disable_validation
  validates_presence_of :file, :if => Proc.new { |o| o.validate_file }
  validates_presence_of :title, :if => Proc.new { |o| !o.disable_validation }
  validates_presence_of :random, :if => Proc.new { |o| !o.disable_validation }
  
  def self.next_track(current_id = nil)
    # Random
    random = rand(100000).to_i
    track = Track.where(:random.gt => random, :_id.ne => current_id).sort(:random).first
    track = Track.where(:random.lt => random, :_id.ne => current_id).sort(:random).first if track.nil?
    return track
  end
  
  def to_json(*a)
    { 
      :id => id,
      :title => title 
    }.to_json(*a)
  end
  
end

