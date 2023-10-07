require 'yaml'
require 'active_record'
require 'active_model'
require_relative 'utils/sc_utils'



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
  # include ActiveModel::Validations
  enum :status, [:default, :rated, :watched, :watchlisted]
  validates_presence_of :title, :sc_url_id, :sc_url_name
  validates_uniqueness_of :sc_url_id, :sc_url_name, :imdb_id
  validates_numericality_of :sc_url_id, { only_integer: true }
  validates_numericality_of :duration, { only_integer: true, allow_nil: true }
  validates_numericality_of :rating, { only_integer: true, allow_nil: true }
  validates_inclusion_of :rating, :in => 0..10
  validates_format_of :imdb_id, with: /\Att\d\d\d\d\d\d\d\z/
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

SenscritiqueUtils.parse_movie_from_wiki("bienvenue_a_gattaca", 488559)
