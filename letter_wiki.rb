require 'rubygems'
require 'restclient'
require 'crack'
WURL = 'http://en.wikipedia.org/w/api.php?action=opensearch&namespace=0&suggest=&search='


('A'..'Z').to_a.each do |letter|
  resp = RestClient.get("#{WURL}#{letter}", 'User-Agent' => 'Ruby')
  arr = Crack::JSON.parse(resp)
  puts arr.join(', ')
 sleep 0.5
end
