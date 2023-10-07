require 'yaml'
require 'active_record'
require 'active_model'
require_relative 'utils/sc_utils'
require_relative 'config/cookies'



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

db_config_file = File.open('./db/database.yaml')
db_config = YAML::load(db_config_file)
ActiveRecord::Base.establish_connection(db_config)





###################
# SCHEMA / MODELS #
###################

class Movie < ActiveRecord::Base
  enum :status, [:default, :rated, :watched, :wishlisted]
  validates_presence_of :title, :sc_url_id, :sc_url_name
  validates_uniqueness_of :sc_url_id, :sc_url_name
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



# https://www.senscritique.com/film/bienvenue_a_gattaca/488559
# https://old.senscritique.com/wiki/bienvenue_a_gattaca/488559

# movie = Movie.new({
#   title: "Bienvenue à Gattaca",
#   sc_url_id: 488559,
#   sc_url_name: "bienvenue_a_gattaca",
#   imdb_id: "tt0119177",
#   director: "Andrew Niccol",
#   country: "USA",
#   rating: 10,
#   status: :rated,
#   category: "Film"
#   original_title: "Gattaca",
#   release_date: Date.parse('24/10/1997'),
#   duration: 106
# })
# movie.save!


last_page = SenscritiqueUtils.get_last_page(Cookies::USERNAME)

(1..last_page).each do | page_number |
  page = SenscritiqueUtils.get_movies_personal_rating_from_page(Cookies::USERNAME, page_number)

  sleep(0.2)

  page.each do |k, v|
    puts "> #{v[:title]}"
    movie_from_wiki = SenscritiqueUtils.get_movie_from_wiki(v[:sc_url_name], v[:sc_url_id])
    hashed_movie = v.merge(movie_from_wiki)

    old_movie = Movie.where(sc_url_id: v[:sc_url_id]).first
    if (old_movie) then
      old_movie.update!(hashed_movie)
      puts ">>> updated"
    else
      movie = Movie.new(hashed_movie)
      movie.save!
      puts ">>> created"
    end
    sleep(0.2)
  end
end
