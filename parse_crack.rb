require "rubygems"
require "rest-client"
res = RestClient.get("http://en.wikipedia.org/wiki")
puts res.code
#=> 200

puts res.body
