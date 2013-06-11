# STEP 1/3
#
# PRE: This reads from the Wikipedia listing for the S&P 500
#
# POST: This creates a SQLite3 db named sp500-data.sqlite
# with a `companies` table

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'sqlite3'

URL='http://en.wikipedia.org/wiki/List_of_S%26P_500_companies'

SUBDIR = 'data-hold'
Dir.mkdir(SUBDIR) unless File.exists?SUBDIR

DBNAME = "#{SUBDIR}/sp500-data.sqlite"
DB = SQLite3::Database.new( DBNAME )

DB.execute("DROP TABLE IF EXISTS companies;")
DB.execute("CREATE TABLE companies(id INTEGER PRIMARY KEY AUTOINCREMENT, name, ticker_symbol, sector, city, state)")




rows = Nokogiri::HTML(open(URL)).css('table.sortable tr')[1..-1]
puts "Number of rows: #{rows.length}"
rows.each do |row|
  tds = row.css('td').map{|td| td.text.strip}
  puts tds.join(", ")
  DB.execute("INSERT INTO companies(name, ticker_symbol, sector, city, state) VALUES(?, ?, ?, ?, ?)", tds[1], tds[0], tds[3], tds[4].split(', '))
end


DB.execute "CREATE INDEX sector_co_idx ON companies(sector)"
DB.execute "CREATE INDEX ticker_symbol_co_cidx ON companies(ticker_symbol)"
DB.execute "CREATE INDEX state_co_idx ON companies(state)"
DB.execute "CREATE INDEX name_co_idx ON companies(name)" 
DB.execute "CREATE INDEX city_co_idx ON companies(city)" 
