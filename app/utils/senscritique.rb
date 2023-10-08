require 'nokogiri'
require_relative 'http'

class Senscritique

	def self.init(config)
		@@CONFIG = config
		@@USERNAME = config["username"]
		@@DELAY = config["http"]["request_delay"]
	end

	# @param username Name of the user to scan
	# @return [Integer] The number of the last page in the collection
	def self.get_last_page(type)
		html = Http.get("/#{@@USERNAME}/collection/all/#{type}/all/all/all/all/all/all/list/page-1")
		if html.css(".eipa-page").empty? then # Only 1 page in the collection
			return 1
		else # Multiple pages
			return html.css(".eipa-page > a").last.text.strip.scan(/\d+/).first.to_i
		end
	end

	# Converts a date string coming from the release dates page to a usable Date object
	# @param date_str [String] Date string from Senscritique wiki page
	# @return [Date, nil]
	def self.parse_date(date_str)
		return nil if date_str.nil?
		return Date.strptime(date_str, '%Y') if date_str =~ /^\d{4}$/ # sometimes, date is just a year
		return Date.strptime(date_str, '%m/%Y') if date_str =~ /^\d{2}\/\d{4}$/ # sometimes, there's also a month
		return Date.strptime(date_str, '%d/%m/%Y')
	end

end
