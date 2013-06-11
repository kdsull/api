require 'rubygems'
require 'rest-client'
require 'nokogiri'
BASE_URL = 'http://public.pcso.us/jail/'
local_pages = Dir.glob('data-hold/*.html').sort_by{|p| p.match(/\d+/)[0].to_i}

count = 0
local_pages.each do |pgnum|
  puts pgnum
  page = Nokogiri::HTML(open(pgnum))
  links = page.css('#MyGridView td a[target="_blank"]')
  links.each do |link|
    url = "#{BASE_URL}#{link['href']}"
    puts url
    r_page = RestClient.get(url)
    fn = link.text.strip
    File.open("data-hold/pages/#{fn}.html", 'w'){|file| file.write(r_page)}
    sleep rand
  end
  count += links.length
end

puts count

