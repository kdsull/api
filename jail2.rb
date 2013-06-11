require 'rubygems'
require 'mechanize'
require 'fileutils'

REGEX = /javascript:__doPostBack\('MyGridView','(Page\$\d+)'\)/
TARGET = 'MyGridView'
SUBDIR = "data-hold/_pcsojail"  #TK changedir
FileUtils.makedirs(SUBDIR)

URL = 'http://public.pcso.us/jail/history.aspx'
agent = Mechanize.new()
agent.get(URL)

agent.page.forms[0]['txtLASTNAME'] = '%'
agent.page.forms[0]['txtFIRSTNAM'] = '%'
agent.page.forms[0].click_button

#puts agent.page.links.map{|t| t.href}
page_links = agent.page.links.map{ |link| 
  if (k = link.href.match(REGEX)) #&& k[1].text.strip =~ /\d+/
    k[1] 
  end
}.compact

# edge case: the first page of results
puts "Writing first page of results"
File.open("#{SUBDIR}/1.html", 'w'){|f| f.write(agent.page.parser.to_html)}
max_page_val_visited = 1

while (page_val = page_links.shift)
  p_num = page_val.match(/\d+(?=$)/)[0].to_i
  if max_page_val_visited >= p_num
    # already visited this page, do nothing. Kind of a sloppy way to avoid
    # infinite loop on last page. Oh well - Dan
    
  elsif max_page_val_visited < p_num
    max_page_val_visited = p_num   
    puts page_val
  
    agent.page.forms[0]['txtLASTNAME'] = '%'
    agent.page.forms[0]['txtFIRSTNAM'] = '%'
    agent.page.forms[0]['__EVENTTARGET'] = TARGET
    agent.page.forms[0]['__EVENTARGUMENT'] = page_val
  
    agent.page.forms[0].submit
    sleep 1
  
    File.open("#{SUBDIR}/#{p_num}.html", 'w'){|f| f.write(agent.page.parser.to_html)}    
    if page_links.empty?
      page_links = agent.page.links.map{|link| k = link.href.match(REGEX); k[1] if k }.compact[1..-1]
    end
    
  end
end

 

#__EVENTTARGET:MyGridView
#__EVENTARGUMENT:Page$30
