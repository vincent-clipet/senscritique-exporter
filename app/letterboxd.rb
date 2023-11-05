require 'yaml'
require 'active_record'
require 'active_model'
require 'csv'





##########
# CONFIG #
##########

# Dir.chdir("app")
CONFIG = YAML::load(File.open('./config/config.yaml'))





##############
# CONNECTION #
##############

def database_exists?
  ActiveRecord::Base.connection
rescue ActiveRecord::NoDatabaseError
  false
else
  true
end
# Database configuration
ActiveRecord::Base.establish_connection(CONFIG["database"])





###################
# SCHEMA / MODELS #
###################

class Movie < ActiveRecord::Base
end





#######
# RUN #
#######

## Watchlist
watchlist_path = "./db/letterboxd_watchlist.csv"
watchlist_headers = [
  "personal_id", "personal_title",
  "imdbID", "Title",
  "Year", "Directors"
]
CSV.open(watchlist_path, 'w', write_headers: true, headers: watchlist_headers) do | csv |
  Movie.where(status: 3).each do | movie |
    csv << [
      movie.id,
      movie.title,
      movie.imdb_id,
      movie.original_title.nil? ? movie.title : movie.original_title,
      movie.release_date&.year,
      movie.director
    ]
  end
end
puts "Watchlist saved to : '#{watchlist_path}'"

## Collection
collection_path = "./db/letterboxd_collection.csv"
collection_headers = [
  "personal_id", "personal_title",
  "imdbID", "Title",
  "Year", "Directors",
  "Rating10",
  "WatchedDate"
]
CSV.open(collection_path, 'w', write_headers: true, headers: collection_headers) do | csv |
  Movie.where(status: [1,2]).each do | movie |
    csv << [
      movie.id,
      movie.title,
      movie.imdb_id,
      movie.original_title.nil? ? movie.title : movie.original_title,
      movie.release_date&.year,
      movie.director,
      movie.rating,
      movie.watched_on
    ]
  end
end
puts "Collection saved to : '#{collection_path}'"
