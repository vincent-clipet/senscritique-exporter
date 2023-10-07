# typed: true

require_relative "../config/cookies"
require_relative "./cookies_utils"
require 'faraday'
require 'nokogiri'

module SenscritiqueUtils



	sc_old = Faraday.new(
		url: "https://old.senscritique.com/",
		headers: {
			'Cookie' => CookiesUtils::get_cookies_string(),
		}
	)
	sc = Faraday.new(
		url: "https://www.senscritique.com/",
		headers: {
			'Cookie' => CookiesUtils::get_cookies_string(),
		}
	)



	# @param sc_url_name The name of the movie, as displayed in the URL
  # @param sc_url_id The ID of the movie, as displayed in the URL
	# @return Hash containing all wiki info
  def self.get_movie_from_wiki(sc_url_name, sc_url_id)

    response = sc_old.get("/wiki/#{sc_url_name}/#{sc_url_id}")
    html = Nokogiri::HTML(response.body)
		info_list = html.css(".ped-row > .ped-results")

		ret = {
			:title => info_list[0].at_css(".ped-results-item > .ped-results-value").text.strip,
			:sc_url_id => sc_url_id,
			:sc_url_name => sc_url_name,
			:imdb_id => info_list[5].at_css(".ped-results-item > .ped-results-value").text.strip,
			:director => info_list[3].at_css(".ped-results-item > .ped-results-value").text.strip,
			:country => info_list[10].at_css(".ped-results-item > .ped-results-value").text.strip,
			# :rating => nil,
			# :status => nil,
			:category => info_list[2].at_css(".ped-results-item > .ped-results-value").text.strip,
			:original_title => info_list[1].at_css(".ped-results-item > .ped-results-value").text.strip,
			:release_date => parse_date(info_list[6].at_css(".ped-results-item > .ped-results-value").text.strip),
			:duration => info_list[11].at_css(".ped-results-item > .ped-results-value").text.strip.split(" ")[0].to_i
		}
		return ret
  end

	# @param sc_url_name The name of the movie, as displayed in the URL
  # @param sc_url_id The ID of the movie, as displayed in the URL
	# @return Hash containing rating & status
  def self.get_movie_personal_rating(sc_url_name, sc_url_id)
		response = sc.get("/film/#{sc_url_name}/#{sc_url_id}")
		html = Nokogiri::HTML(response.body)
		info_list = html.css(".ped-row > .ped-results")
  end



private

	# Converts a date string coming from the release dates page to a usable Date object
	# @param date_str [String] Date string from Senscritique wiki page
	# @return [Date, nil]
	def self.parse_date(date_str)
		return nil if date_str.nil?
		return Date.strptime(date_str, '%d/%m/%Y')
	end

end
