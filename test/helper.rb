require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'
require 'database_cleaner'
require 'faker'
require 'sham'
require File.dirname(__FILE__) + '/../lib/proton_server'
require File.dirname(__FILE__) + '/blueprints'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

DatabaseCleaner.strategy = :truncation

class Test::Unit::TestCase
  
  def setup
    Sham.reset
    DatabaseCleaner.start
    MongoMapper.database = "mostrated_test"
  end
  
  def teardown
    DatabaseCleaner.clean
  end
  
  # Looks for a document in the files collection on the test database
  def assert_stored_file(track)
    @db = Mongo::Connection.new.db("mostrated_test")
    assert @db.collection("fs.files").find({"_id"=>@track.file.id}).count > 0
  end
end
