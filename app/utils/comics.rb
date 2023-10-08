class Comic < ActiveRecord::Base
  enum :status, [:default, :rated, :watched, :wishlisted]
  validates_presence_of :title, :sc_url_id, :sc_url_name
  validates_uniqueness_of :sc_url_id
  validates_numericality_of :sc_url_id, { only_integer: true }
  validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true
end



class Comics < Senscritique

  def self.init()
    unless Comic.table_exists? then
      ActiveRecord::Schema.define do
        create_table :comics do |t|
          t.string :title, index: true
          t.integer :sc_url_id, index: true
          t.string :sc_url_name, index: true
          t.string :author, index: true
          t.string :original_title
          t.integer :rating, index: true
          t.integer :status, default: 0, index: true
          t.date :release_date
        end
      end
    end
  end

  # Comics don't have a wiki
  def self.wiki_for(url_name, url_id)
    return {}
  end

  # Need to overwrite this from parent to get more info while scraping,
  # given that there are no wiki pages for Comics
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
        :title => item.at_css(".elco-product-detail > .elco-title > a").text,
        :rating => nil,
        :author => item.at_css(".elco-product-detail > .elco-baseline > a").text,
        :original_title => nil,
        :release_date => nil
      }

      potential_release_date = item.at_css(".elco-product-detail > .elco-title > .elco-date")
      if (potential_release_date) then
        hash[:release_date] = parse_date(potential_release_date.text&.strip&.tr("()", ""))
      end

      potential_original_title = item.at_css(".elco-product-detail > .elco-original-title")
      if (potential_original_title) then
        hash[:original_title] = potential_original_title.text&.strip
      end

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
