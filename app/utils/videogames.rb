class VideoGame < ActiveRecord::Base
  enum :status, [:default, :rated, :watched, :wishlisted]
  validates_presence_of :title, :sc_url_id, :sc_url_name
  validates_uniqueness_of :sc_url_id
  validates_numericality_of :sc_url_id, { only_integer: true }
  validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true
end



class VideoGames < Senscritique

  def self.init()
    unless VideoGame.table_exists? then
      ActiveRecord::Schema.define do
        create_table :video_games do |t|
          t.string :title, index: true
          t.integer :sc_url_id, index: true
          t.string :sc_url_name, index: true
          t.string :developer, index: true
          t.string :publisher, index: true
          t.integer :rating, index: true
          t.integer :status, default: 0, index: true
          t.string :category, index: true
          t.string :original_title
          t.date :release_date
        end
      end
    end
  end

  # @param url_name The name of the item, as displayed in the URL
  # @param url_id The ID of the item, as displayed in the URL
  # @return [Hash] partial Hash containing all wiki info for this item
  def self.wiki_for(url_name, url_id)
    html = Http.get_authentified("/wiki/#{url_name}/#{url_id}")
    return {} if html.nil? # 301 redirect

    info_list = html.css(".ped-row > .ped-results")
    ret = {
      :title => info_list[0].at_css(".ped-results-item > .ped-results-value")&.text&.strip,
      :sc_url_id => url_id.to_i,
      :sc_url_name => url_name,
      :developer => info_list[3].at_css(".ped-results-item > .ped-results-value")&.text&.strip,
      :publisher => info_list[4].at_css(".ped-results-item > .ped-results-value")&.text&.strip,
      :category => info_list[2].at_css(".ped-results-item > .ped-results-value")&.text&.strip,
      :original_title => info_list[1].at_css(".ped-results-item > .ped-results-value")&.text&.strip,
      :release_date => parse_date(info_list[8].at_css(".ped-results-item > .ped-results-value")&.text&.strip),
    }
    return ret
  end

end
