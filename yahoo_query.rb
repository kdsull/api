
#
# PRE: This reads from an existing file called sp500-data.sqlite
# which should have a `companies` table
#
# POST: This downloads .csv files for every company in `companies`

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'sqlite3'

START_DATE=['01','01','2008']
END_DATE=['10','01','2011']

YURL="http://ichart.finance.yahoo.com/table.csv?a=#{START_DATE[0]}&b=#{START_DATE[1]}&c=#{START_DATE[2]}&d=#{END_DATE[0]}&e=#{END_DATE[1]}&f=#{END_DATE[2]}&g=d&ignore=.csv&s="
DBNAME = "data-hold/sp500-data.sqlite"
DB = SQLite3::Database.new( DBNAME )


SUBDIR = 'data-hold/yahoo-data'
Dir.mkdir(SUBDIR) unless File.exists?SUBDIR

DB.execute("SELECT DISTINCT ticker_symbol from companies").each do |sym|
  fname = "#{SUBDIR}/#{sym}.csv"
  unless File.exists?fname
    puts fname
    d = open("#{YURL}#{sym}")
    File.open(fname, 'w') do |ofile|
      ofile.write(d.read)
      sleep(1.5 + rand)
    end
  end  
end

Return to chapter outline
Storing stock data into SQLite

# STEP 3/3
# This reads from .csv files in SUBDIR_DATA and builds out several tables
# in an already existing sp500-data.sqlite file

# PRE: This reads from an existing file called sp500-data.sqlite
# which should have a `companies` table
#
# POST: This downloads .csv files for every company in `companies`
#
# NOTE: This script took about an 15 minutes to run

require 'rubygems'
require 'sqlite3'

SUBDIR = 'data-hold'
SUBDIR_DATA = "#{SUBDIR}/yahoo-data"

DBNAME = "#{SUBDIR}/sp500-data.sqlite"
DB = SQLite3::Database.new( DBNAME )
C_FIELDS = %w(name ticker_symbol sector city state)
S_FIELDS = %w(date open high low close volume closing_price)

DATE_FD_INDEX = (S_FIELDS).index('date')
DB.execute("DROP TABLE IF EXISTS stock_prices;")
DB.execute("DROP TABLE IF EXISTS companies_and_stocks;")

DB.execute("CREATE TABLE stock_prices(#{S_FIELDS.map{|f| f=~/date/ ? f : "#{f} NUMERIC" }.join(',')}, company_id INTEGER)")
DB.execute("CREATE TABLE companies_and_stocks(#{(C_FIELDS+S_FIELDS).map{|f| f=~/date|name|ticker_symbol|sector|city|state|date/ ? f : "#{f} NUMERIC" }.join(',')})")

## Make company ID hash for faster reference
## companies table must already exist
co_ids = DB.execute("SELECT id, ticker_symbol FROM companies GROUP BY ticker_symbol").inject({}) do |hsh, c|
  hsh[c[1].to_s] = c[0].to_i
  hsh 
end


s_insert_sql = "INSERT INTO stock_prices VALUES(#{(S_FIELDS.length+1).times.map{'?'}.join(',')})"
cns_insert_sql = "INSERT INTO companies_and_stocks(#{(C_FIELDS+S_FIELDS).join(',')}) VALUES(#{(C_FIELDS+S_FIELDS).map{'?'}.join(',')})"

insert_sp_stmt = DB.prepare(s_insert_sql)
cns_stmt = DB.prepare(cns_insert_sql)


## Build out tables
DB.execute("SELECT DISTINCT ticker_symbol from companies").each do |sym|
  fname = "#{SUBDIR_DATA}/#{sym}.csv"
  puts fname
  co_id = co_ids[sym.to_s]
  co_data = DB.execute("SELECT #{C_FIELDS.join(',')} from companies where ticker_symbol = ?", sym)
    
  File.open(fname, 'r') do |csv|
    csv.readlines[1..-1].map{|r| r.strip.split(',')}.each do |cols|
      insert_sp_stmt.execute(cols, co_id)      
      # For the database in the SQL chapter,  I have truncated the companies_and_stocks
      # table to a smaller sample      
      cns_stmt.execute(co_data, cols) if cols[DATE_FD_INDEX] > "2011-08"
    end
  end
end

# Create indicies for faster queries
DB.execute "CREATE INDEX company_id_index ON stock_prices(company_id)"
DB.execute "CREATE INDEX date_index ON stock_prices(date)" 
DB.execute "CREATE INDEX name_idx ON companies_and_stocks(name)" 
DB.execute "CREATE INDEX ticker_idx ON companies_and_stocks(ticker_symbol)" 
DB.execute "CREATE INDEX city_idx ON companies_and_stocks(city)" 
DB.execute "CREATE INDEX state_idx ON companies_and_stocks(state)" 
DB.execute "CREATE INDEX sector_idx ON companies_and_stocks(sector)" 
DB.execute "CREATE INDEX date_idx ON companies_and_stocks(date)" 


