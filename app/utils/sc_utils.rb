# typed: true

require_relative "../config/cookies"
require_relative "./cookies_utils"
require 'faraday'
require 'nokogiri'

module SenscritiqueUtils



	@@sc_old = Faraday.new(
		url: "https://old.senscritique.com/",
		headers: {
			'Cookie' => CookiesUtils::get_cookies_string(),
		}
	)
	@@sc = Faraday.new(
		url: "https://old.senscritique.com/"
	)



	# @param sc_url_name The name of the movie, as displayed in the URL
	# @param sc_url_id The ID of the movie, as displayed in the URL
	# @return [Hash] partial movie Hash containing all wiki info
	def self.get_movie_from_wiki(sc_url_name, sc_url_id)
		response = @@sc_old.get("/wiki/#{sc_url_name}/#{sc_url_id}")

		return {} unless response.status == 200 # sometimes the wiki is not accessible, and redirects with 301

		html = Nokogiri::HTML(response.body)
		info_list = html.css(".ped-row > .ped-results")

		ret = {
			:title => info_list[0].at_css(".ped-results-item > .ped-results-value")&.text&.strip,
			:sc_url_id => sc_url_id,
			:sc_url_name => sc_url_name,
			:imdb_id => info_list[5].at_css(".ped-results-item > .ped-results-value")&.text&.strip,
			:director => info_list[3].at_css(".ped-results-item > .ped-results-value")&.text&.strip,
			:country => info_list[10].at_css(".ped-results-item > .ped-results-value")&.text&.strip,
			# :rating => nil,
			# :status => nil,
			:category => info_list[2].at_css(".ped-results-item > .ped-results-value")&.text&.strip,
			:original_title => info_list[1].at_css(".ped-results-item > .ped-results-value")&.text&.strip,
			:release_date => parse_date(info_list[6].at_css(".ped-results-item > .ped-results-value")&.text&.strip),
			:duration => info_list[11].at_css(".ped-results-item > .ped-results-value")&.text&.strip&.split(" ")&.first&.to_i
		}
		return ret
	end


	# @param username Name of the user to scan
	# @param page ID of the collection
	# @return [Hash] partial movie Hash containing rating & status
	def self.get_movies_personal_rating_from_page(username, page)
		response = @@sc.get("/#{username}/collection/all/films/all/all/all/all/all/all/all/page-#{page}")
		html = Nokogiri::HTML(response.body)

		movie_list = html.css(".elco-collection > .elco-collection-list > .elco-collection-item")
		ret = {}

		movie_list.each do | movie |
			# Get sc_url_name & sc_url_id
			split_url = movie.css(".elco-product-detail > .elco-title > a").first['href'].split("/")
			id = split_url[3]

			movie_hash = {
				:sc_url_id => id,
				:sc_url_name => split_url[2],
				:rating => nil,
				:title => movie.css(".elco-product-detail > .elco-title > a").text
			}

			potential_rating = movie.at_css(".elco-collection-rating.user .elrua-useraction-action > .elrua-useraction-inner")
			if (movie.css(".eins-wish-list").any?) then
				movie_hash[:status] = :wishlisted
			elsif (movie.css(".eins-done").any?)
				movie_hash[:status] = :watched
			# 1 child -> it's a rating
			elsif (potential_rating.children.size == 1)
				movie_hash[:status] = :rated
				movie_hash[:rating] = potential_rating&.child&.text&.strip&.to_i
			end

			ret[id] = movie_hash
		end

		return ret
	end


	def self.get_last_page(username)
		response = @@sc.get("/#{username}/collection/all/films/my_rating/all/all/all/all/all/list/page-1")
		html = Nokogiri::HTML(response.body)
		if html.css(".eipa-page").empty?
			return 1
		else
			return html.css(".eipa-page > a").last.text.strip.scan(/\d+/).first.to_i
		end
	end



private

	# Converts a date string coming from the release dates page to a usable Date object
	# @param date_str [String] Date string from Senscritique wiki page
	# @return [Date, nil]
	def self.parse_date(date_str)
		return nil if date_str.nil?
		return Date.strptime(date_str, '%Y') if date_str =~ /\d{4}/
		return Date.strptime(date_str, '%d/%m/%Y')
	end

end
