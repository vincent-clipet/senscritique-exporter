require 'yaml'
require 'active_record'
require 'active_model'
require_relative 'utils/sc_utils'



##########
# CONFIG #
##########

Dir.chdir("app")

CONFIG = YAML::load(File.open('./config/config.yaml'))
CONFIG_DB = CONFIG["database"]
USERNAME = CONFIG["username"]
DELAY = CONFIG["http"]["request_delay"]
CONFIG_COOKIES = CONFIG["cookies"]
COOKIES_STRING = CONFIG_COOKIES.map { |key, value| "#{key}=#{value}" } .join('; ')

SenscritiqueUtils.init(COOKIES_STRING)



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

ActiveRecord::Base.establish_connection(CONFIG_DB)



###################
# SCHEMA / MODELS #
###################

class Movie < ActiveRecord::Base
	enum :status, [:default, :rated, :watched, :wishlisted]
	validates_presence_of :title, :sc_url_id, :sc_url_name
	validates_uniqueness_of :sc_url_id
	validates_numericality_of :sc_url_id, { only_integer: true }
	validates_numericality_of :duration, { only_integer: true, allow_nil: true }
	validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true
	validates :imdb_id, format: { with: /\Att\d+\z/ }, allow_blank: true, allow_nil: true, uniqueness: true
end

unless Movie.table_exists? then
	ActiveRecord::Schema.define do
		create_table :movies do |t|
			t.string :title, index: true
			t.integer :sc_url_id, index: true
			t.string :sc_url_name, index: true
			t.string :imdb_id, index: true
			t.string :director, index: true
			t.string :country, index: true
			t.integer :rating, index: true
			t.integer :status, default: 0, index: true
			t.string :category, index: true
			t.string :original_title
			t.date :release_date
			t.integer :duration
		end
	end
end



#######
# RUN #
#######

movies_updated = 0
movies_created = 0

last_page = SenscritiqueUtils.get_movies_last_page(USERNAME)

(1..last_page).each do | page_number |
	puts "----- Movies - page #{page_number}/#{last_page} -----"
	page = SenscritiqueUtils.get_movies_personal_rating_from_page(USERNAME, page_number)

	sleep(DELAY)

	page.each do |k, v|
		puts "> #{v[:title]}"
		movie_from_wiki = SenscritiqueUtils.get_movie_from_wiki(v[:sc_url_name], v[:sc_url_id])
		hashed_movie = v.merge(movie_from_wiki)

		old_movie = Movie.where(sc_url_id: v[:sc_url_id]).first
		if (old_movie) then
			old_movie.update!(hashed_movie)
			movies_updated += 1
		else
			movie = Movie.new(hashed_movie)
			movie.save!
			movies_created += 1
		end
		sleep(DELAY)
	end
end

puts "============================================"
puts ">>> #{movies_created} new movies"
puts ">>> #{movies_updated} updated movies"
puts "============================================"
