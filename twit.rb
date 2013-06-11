require 'rubygems'
require 'restclient'
require 'crack'

# Twitter only allows you to go back 3,200 tweets for any given user
MAX_NUMBER_OF_TWEETS = 3200

# The maxmimum number of tweets you can get per request is 200
NUMBER_OF_TWEETS_PER_PAGE = 200
# Here is where we set the user whose tweets we want to get
TARGET_USERNAME = 'Tenaris'

# This is the directory where we want to store the tweet collection
DATA_DIRECTORY = "data-hold"

Dir.mkdir(DATA_DIRECTORY) unless File.exists?(DATA_DIRECTORY)

GET_USERINFO_URL = "http://api.twitter.com/1/users/show.xml?screen_name=#{TARGET_USERNAME}"
GET_STATUSES_URL = "http://api.twitter.com/1/statuses/user_timeline.xml?screen_name=#{TARGET_USERNAME}&trim_user=true&count=#{NUMBER_OF_TWEETS_PER_PAGE}&include_retweets=true&include_entities=true"

user_info = RestClient.get(GET_USERINFO_URL)

if user_info.code != 200
  
   # Did not get a correct response from Twitter. Do nothing.
    puts "Failed to get a correct response from Twitter. 
      Response code is: #{user_info.code}"
      
else
  
  # successful response from Twitter
  File.open("#{DATA_DIRECTORY}/userinfo-#{TARGET_USERNAME}.xml", 'w'){|ofile|
    ofile.write(user_info.body)
  }

  # The total number of a user's tweets is the value
  # in the "statuses_count" field
  statuses_count = (Crack::XML.parse(user_info)['user']['statuses_count']).to_f
  puts "#{TARGET_USERNAME} has #{statuses_count} status updates\n\n"


  # Calculate the number of pages by dividing the user's 
  #   number of Tweets (statuses_count) by the maximum number of past 
  #   tweets that Twitter allows us to retrieve (max_number_of_tweets = 3200)
  number_of_pages = ([MAX_NUMBER_OF_TWEETS, statuses_count].min/NUMBER_OF_TWEETS_PER_PAGE).ceil
  puts "This script will iterate through #{number_of_pages} pages"

  File.open("#{DATA_DIRECTORY}/tweets-#{TARGET_USERNAME}.xml", 'w'){ |outputfile_user_tweets|
    (1..number_of_pages).each do |page_number|
      tweets_page = RestClient.get("#{GET_STATUSES_URL}&page=#{page_number}")
      puts "\t Fetching page #{page_number}"
      if tweets_page.code == 200  
        outputfile_user_tweets.write(tweets_page.body)
        puts "\t\tSuccess!"
      else
        puts "\t\t Failed. Response code: #{tweets_page.code}"
      end  
      sleep 2 # pause for a couple seconds
    end
  } # closing outputfile_user_tweets File handle

end # end of if user_info...
