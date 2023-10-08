require 'yaml'
require 'active_record'
require 'active_model'
require_relative 'utils/senscritique'
require_relative 'utils/movies'
require_relative 'utils/series'
require_relative 'utils/books'
require_relative 'utils/comics'



##########
# CONFIG #
##########

Dir.chdir("app")

CONFIG = YAML::load(File.open('./config/config.yaml'))
COOKIES = CONFIG["cookies"].map { |key, value| "#{key}=#{value}" } .join('; ')
EXPORT = CONFIG["export"]



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

ActiveRecord::Base.establish_connection(CONFIG["database"])



###################
# SCHEMA / MODELS #
###################





#######
# RUN #
#######

Senscritique.init(CONFIG)
Http.init(COOKIES)

if (EXPORT["movies"]) then
  Movies.init()
  Movies.run(Movie, "movies")
end

if (EXPORT["series"]) then
  Series.init()
  Series.run(Serie, "series")
end

if (EXPORT["books"]) then
  Books.init()
  Books.run(Book, "livres", "books")
end

if (EXPORT["comics"]) then
  Comics.init()
  Comics.run(Comic, "bd", "comics")
end
