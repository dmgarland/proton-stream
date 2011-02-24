require 'machinist/mongo_mapper'
require 'sham'

Sham.define do
	title       { Faker::Lorem.words.join ' ' }
	random      { rand(100000) }
end

Track.blueprint do
  title
  random
end

