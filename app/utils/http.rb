require 'faraday'

module Http

	# Needs to be called once before doing anything
	# Sets up HTTP clients
	def self.init(cookies)
		# Need auth to access wiki pages
		@@sc_old = Faraday.new(
			url: "https://old.senscritique.com/",
			headers: {
				'Cookie' => cookies,
			}
		)
		# No auth needed for everything else
		@@sc = Faraday.new(
			url: "https://old.senscritique.com/"
		)
	end

  def self.get(partial_url)
    return get_html(partial_url, @@sc)
  end

  def self.get_authentified(partial_url)
		return get_html(partial_url, @@sc_old)
  end



  private



  def self.get_html(partial_url, http_client)
    response = http_client.get(partial_url)
		# sometimes the wiki is not accessible, and redirects with 301 (for recent movies for example)
		return response.status == 200 ? Nokogiri::HTML(response.body) : nil
  end

end
