require 'helper'

class TrackTest < Test::Unit::TestCase

  context "The Track class" do
    setup do
      10.times { Track.make }
    end
    
    should "be able to return a random track" do      
      track_one = Track.next_track
      assert_not_nil track_one      
      assert_not_equal track_one, Track.next_track(track_one._id)
    end
  end
  
  context "A track" do
    
    setup do
      @track = Track.make
      @file_name = "somefile.mp3"
      File.open(@file_name, "w+") { |f| f << "hi" * 100 }
    end
    
    should "not validate the presence of a file by default" do
      assert @track.valid?
      # Turn on file validation
      @track.validate_file = true
      assert_equal false, @track.valid?
      assert @track.errors.full_messages.include? "File can't be empty"
    end
    
    should "handle a track upload" do
      
      @track.file = File.new(@file_name)
      @track.save!
      
      assert_not_nil @track.file.id
      assert_not_nil @track.file.size
      assert_not_nil @track.file.type
      assert_not_nil @track.file.name      
      assert_stored_file @track      
    end
    
    should "generate only relevant json" do
      assert_equal "{\"title\":\"corporis neque dolorum\",\"id\":\"#{@track._id}\"}", @track.to_json
    end
    
    teardown do
      FileUtils.rm_f 'somefile.mp3' if File.exist? 'somefile.mp3'
    end
  
  end
  
end