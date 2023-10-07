require_relative '../config/cookies'

module CookiesUtils

  def self.get_cookies_string()
    return Cookies::SC.map { |key, value| "#{key}=#{value}" } .join('; ')
  end

end
