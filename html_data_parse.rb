class String
  def h_strip
    self.gsub(/(?:\302\240)|\s|\r/, ' ').strip
  end
end

require 'rubygems'
require 'nokogiri'
require 'sqlite3'
require 'chronic'

lists_dir = "data-hold"
pages_dir = "#{lists_dir}/pages"
bookings_table = "bookings"
charges_table = "charges"
DBNAME = "#{lists_dir}/pcso-jail-archive.sqlite"

CHARGES_LBLS = %w(code name category degree bond bond_posted_time)
BOOKING_SPAN_LBLS = [["DataList1_ctl00_FIRSTLabel", "first_name"],   [ "DataList1_ctl00_MIDDLELabel", "middle_name"],   [ "DataList1_ctl00_LAST_NAMELabel", "last_name"],   [ "DataList1_ctl00_CITYLabel", "city"],   [ "DataList1_ctl00_STATELabel", "state"],   [ "DataList1_ctl00_COMMIT_DATELabel", "booking_time"],   [ "DataList1_ctl00_PINLabel", "booking_number"],   [ "DataList1_ctl00_Label1", "release_time"],   [ "DataList1_ctl00_BIRTHLabel", "date_of_birth"],   [ "DataList1_ctl00_RACELabel", "race"],   [ "DataList1_ctl00_SEXLabel", "sex"]]
BOOKING_COLS = BOOKING_SPAN_LBLS.map{|col| col[1]} + ['age', 'sys_id', 'img_id']
CHARGES_COLS = CHARGES_LBLS + ["booking_number", 'code_short']
BIRTH_DATE_IDX = BOOKING_SPAN_LBLS.index{|a| a[1]=='date_of_birth'}
BOOKING_DATE_IDX = BOOKING_SPAN_LBLS.index{|a| a[1]=='booking_time'}

BOOKING_NUMBER_IDX = BOOKING_SPAN_LBLS.index{|a| a[1]=='booking_number'}
BOOKING_DATE_IDXES = BOOKING_SPAN_LBLS.select{|a| a[1] =~ /date|time/ }.map{|a| BOOKING_SPAN_LBLS.index(a)}
CHARGE_CODE_IDX  = CHARGES_LBLS.index('code')
CHARGES_DATE_IDXES = CHARGES_COLS.select{|a| a =~ /date|time/ }.map{|a| CHARGES_COLS.index(a)}

BOOKING_SQL = "INSERT INTO #{bookings_table}(#{BOOKING_COLS.join(',')}) VALUES(#{BOOKING_COLS.map{'?'}.join(',')})"
CHARGES_SQL = "INSERT INTO #{charges_table}(#{CHARGES_COLS.join(',')}) VALUES(#{CHARGES_COLS.map{'?'}.join(',')})"
######## boilerplate stuff



## Building database
File.delete(DBNAME) if File.exists?(DBNAME)
DB = SQLite3::Database.new( DBNAME )
DB.execute("DROP TABLE IF EXISTS #{bookings_table};")
DB.execute("DROP TABLE IF EXISTS #{charges_table};")

DB.execute("CREATE TABLE #{bookings_table}(#{BOOKING_COLS.join(',')})"); 
DB.execute("CREATE TABLE #{charges_table}(#{CHARGES_COLS.join(',')})"); 


## Creating textfiles with headers
BOOKINGS_FILE = File.open("#{lists_dir}/sums/bookings.txt", 'w')
CHARGES_FILE = File.open("#{lists_dir}/sums/charges.txt", 'w')
CHARGES_FILE.puts(CHARGES_COLS.join("\t"))
BOOKINGS_FILE.puts(BOOKING_COLS.join("\t"))

Dir.glob("#{pages_dir}/*.html").each_with_index do |inmate_pagename, count|
    puts "On booking #{count}" if count % 500 ==1

    detail_page = Nokogiri::HTML(open(inmate_pagename))
    sysid,img = detail_page.css("#form1")[0]["action"].match(/SYSID=(\d+)(?:&IMG=(\d+))?/)[1..-1]
    booking_cols = detail_page.css('table#DataList1 span').map{|span| span.text.h_strip}
    booking_cols.each_with_index{ |a, i| booking_cols[i] = Chronic.parse(a).strftime("%Y-%m-%d %H:%M") if BOOKING_DATE_IDXES.index(i) && !a.empty?}
    
   
    age = (Time.parse(booking_cols[BOOKING_DATE_IDX]).to_i - Time.parse( booking_cols[BIRTH_DATE_IDX]).to_i) / 60 / 60 / 24 / 365
    
    
    booking_number = booking_cols[BOOKING_NUMBER_IDX]
    booking_data_row = booking_cols + [age, sysid,img] 
    BOOKINGS_FILE.puts( booking_data_row.join("\t"))
    DB.execute(BOOKING_SQL, booking_data_row)
    
    if charges_rows = detail_page.css('table#GridView1 tr')[1..-2]
       charges_rows.each do |charge_row|
        cols = charge_row.css('td').to_a.map{|td| td.text.h_strip}
        
        cols.each_with_index do |a,i| 
           cols[i] = Chronic.parse(a).strftime("%Y-%m-%d %H:%M") if CHARGES_DATE_IDXES.index(i) && !a.empty?  
        end  
        
        code_short = cols[CHARGE_CODE_IDX].match(/^\d+(?:\.\d+)?/).to_s
        charges_data_row = (cols << [booking_number, code_short])
        CHARGES_FILE.puts( charges_data_row.join("\t"))
        DB.execute(CHARGES_SQL, charges_data_row)
      end
    end

end


DB.execute "CREATE INDEX booking_index ON #{bookings_table}(booking_number)" 
DB.execute "CREATE INDEX booking_index_k ON #{charges_table}(booking_number)"

DB.execute "CREATE INDEX code_index ON #{charges_table}(code)"
DB.execute "CREATE INDEX name_index ON #{charges_table}(name)"
DB.execute "CREATE INDEX code_short_index ON #{charges_table}(code_short)"
