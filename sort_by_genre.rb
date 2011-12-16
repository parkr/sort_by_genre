#!/usr/bin/env ruby

# Idea by Matt Lepage
# Code by Parker Moore

# This script grabs the names of files in the current directory and sorts them by genre, using the Netflix API.
# => 1. Get Titles from Directory
# => 2. Initialize OAuth
# => 3. Iterate through the filenames and search, grabbing the genre for each
# => 4. Place movies in { genre => [movie, titles] } array.
# => 5. Iterate through genres and print list, all alphabetized.

require 'rubygems'
require 'oauth'
require 'nokogiri'
require 'uri'
require 'yaml'

# 0. Set Variables

BASE_URL = "http://api.netflix.com"
GET_CATEGORY = "/catalog/titles" # Netflix API endpoint to get category for movie based on title name

KEY = "tmphbgaxwkkru2ezz9wn88t3"
SECRET = "sdeg5wKMkz"

genres = {}

# 0.5. Extra Functions

class String
  def make_human_title
    self.chomp(File.extname(self)).to_s.gsub(/[-_]/, " ").gsub(/([A-Z]+)([A-Z][a-z])/, '\1 \2').gsub(/([a-z\d])([A-Z])/, '\1 \2')
  end
end


# => 1. Get Titles from Directory

here = Dir.new(File.join(ENV["HOME"], "Movies"))

# => 2. Initialize OAuth

consumer = OAuth::Consumer.new(KEY, SECRET, { :site => BASE_URL })
access_token = OAuth::AccessToken.from_hash(consumer, {})

# => 3. Iterate through the filenames and search, grabbing the genre for each

here.each do |movie|
  unless movie.start_with?(".")
    
    term = movie.make_human_title
    resp = access_token.get("#{GET_CATEGORY}?term=#{URI.encode(term)}&max_results=1").body
    
    Nokogiri.XML(resp).xpath("//catalog_title").map do |xml|
      
      category = xml.at_xpath("./category[@scheme=\"http://api.netflix.com/categories/genres\"]")
      
      while category != nil && category['scheme'] == "http://api.netflix.com/categories/genres"
        
        # => 4. Place movies in { genre => [movie, titles] } array.
        if genres[category['term']]
          genres[category['term']] << term #xml.at_xpath("title")['short']
        else
          genres[category['term']] = [term] #[xml.at_xpath("title")['short']]
        end
        
        category = category.next_element
      end
      
    end
  end
end

# => 5. Iterate through genres and print list, all alphabetized.
genres.sort.map do |arr|
  
  puts arr[0] # genre
  arr[1].map do |movie|
    puts "\t=> #{movie}"
  end
  puts ""
  
end

File.open( 'titles.yml', 'w' ) { |file| YAML.dump(genres, file) } # alternatively, stash the file away and you'll be all good to go later, without an internet connection
