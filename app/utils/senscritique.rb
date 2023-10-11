require 'nokogiri'
require_relative 'http'

class Senscritique

  def self.init(config)
    @@CONFIG = config
    @@USERNAME = config["username"]
    @@DELAY = config["http"]["request_delay"]
  end



  def self.run(model, type_fr, type_en=type_fr)
    updated = 0
    created = 0
    last_page = @@CONFIG["debug"]["page_limit"] == 0 ? get_last_page(type_fr) : @@CONFIG["debug"]["page_limit"]
    puts last_page

    (1..last_page).each do | page_number |
      puts "----- #{type_en.capitalize} - page #{page_number}/#{last_page} -----"
      page = ratings_for(type_fr, page_number)

      sleep(@@DELAY)

      page.each do |k, v|
        from_wiki = wiki_for(v[:sc_url_name], v[:sc_url_id])
        hashed = v.merge(from_wiki)

        old = model.where(sc_url_id: v[:sc_url_id]).first
        if (old) then
          old.update!(hashed)
          updated += 1
          action = "updated"
        else
          model.create!(hashed)
          created += 1
          action = "created"
        end

        puts "(#{action}) > #{v[:title]}"
        sleep(@@DELAY)
      end
    end

    puts "============================================"
    puts ">>> #{created} new #{type_en}"
    puts ">>> #{updated} updated #{type_en}"
    puts "============================================"
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
    return Date.strptime(date_str, '%Y-%m-%d') if date_str =~ /^\d{4}\-\d{2}\-\d{2}$/ # from <time> HTML element
    return Date.strptime(date_str, '%d/%m/%Y')
  end

  # @param page ID of the collection
  # @return [Hash] partial Hash containing rating & status
  def self.ratings_for(type, page)
    html = Http.get("/#{@@CONFIG["username"]}/collection/all/#{type}/all/all/all/all/all/all/all/page-#{page}")

    list = html.css(".elco-collection > .elco-collection-list > .elco-collection-item")
    ret = {}

    # Loop. 18 items per page
    list.each do | item |
      # Get sc_url_name & sc_url_id
      split_url = item.css(".elco-product-detail > .elco-title > a").first['href'].split("/")
      id = split_url[3]

      hash = {
        :sc_url_id => id,
        :sc_url_name => split_url[2],
        :title => item.css(".elco-product-detail > .elco-title > a").text,
        :rating => nil
      }

      potential_rating = item.at_css(".elco-collection-rating.user .elrua-useraction-action > .elrua-useraction-inner")
      # Only wishlisted
      if (item.css(".eins-wish-list").any?) then
        hash[:status] = "wishlisted"
      # Watched but not rated
      elsif (item.css(".eins-done").any?)
        hash[:status] = "watched"
      # 1 child -> it's a rating
      elsif (potential_rating.children.size == 1)
        hash[:status] = "rated"
        hash[:rating] = potential_rating&.child&.text&.strip&.to_i
      end

      ret[id] = hash
    end

    return ret
  end

end
