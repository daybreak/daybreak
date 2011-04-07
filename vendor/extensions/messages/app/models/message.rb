require 'mime/types'

class Message < ActiveRecord::Base
	include ActionView::Helpers::UrlHelper
	include ActionView::Helpers::TagHelper
  include FileColumnHelper

	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'
	belongs_to :series
	validates_presence_of :title
	validates_presence_of :delivered_on

	file_column :outline
	file_column :audio

	file_column :cp_outline
	file_column :cp_audio

	def next_series
		Series.next_series(self)
	end

	def public_audio_file(options = nil)
    url_for_file_column(self, "audio", options)
  end

	def public_outline_file(options = nil)
    url_for_file_column(self, "outline", options)
  end

	def public_cp_audio_file(options = nil)
    url_for_file_column(self, "cp_audio", options)
  end

	def public_cp_outline_file(options = nil)
    url_for_file_column(self, "cp_outline", options)
  end

	def happened?
		delivered_on < DateTime.now
	end

	def number
		self.series.messages.index(self) + 1 rescue 1
	end

	def of_number
		self.series.messages.count rescue 1
	end

	def self.find_since(date = Date.today)
		self.find_between(date, nil)
	end

	def self.find_between(from = Date.today, thru = nil)
		values = {}
		values[:f] = from.kind_of?(String) ? Date.parse(from) : from
		values[:t] = thru.kind_of?(String) ? Date.parse(thru) : thru
		cond = []
		cond << "delivered_on >= :f" if values[:f]
		cond << "delivered_on <= :t" if values[:t]
		conditions = [cond.join(' AND '), values] if cond.length > 0
    self.find(:all, :conditions => conditions, :order => "delivered_on")
	end

	def self.start_of_next_series(message)
		self.find(:first, :conditions => ["delivered_on > :date AND series_id <> :id", {:date => message.delivered_on, :id => message.series_id}], :order => "delivered_on")
	end

	def self.latest_feed
		Message.find(:all, :conditions => 'audio IS NOT NULL', :order => 'delivered_on DESC', :limit => 8).select{|message| message.public_audio_file }
  end

	def self.rss
    author = "Daybreak Church, Mechanicsburg, PA"

    rss = RSS::Rss.new("2.0")
    channel = RSS::Rss::Channel.new

    category = RSS::ITunesChannelModel::ITunesCategory.new("Religion & Spirituality")
    category.itunes_categories << RSS::ITunesChannelModel::ITunesCategory.new("Christianity")
    channel.itunes_categories << category

    channel.title = "Daybreak Weekend Podcast"
		channel.ttl = "60"
    channel.description = "Every day can be a fresh start with God."
    channel.link = Radiant::Config['org.root_url']
    channel.language = "en-us"
    channel.copyright = "Copyright #{Date.today.year}"

    channel.image = RSS::Rss::Channel::Image.new
    #channel.image.url = #TODO: podcast album art
    channel.image.title = channel.title
    channel.image.link = channel.link

    channel.itunes_author = author
    channel.itunes_owner = RSS::ITunesChannelModel::ITunesOwner.new
    channel.itunes_owner.itunes_name = author
    channel.itunes_owner.itunes_email= 'info@daybreakweb.com'

    channel.itunes_keywords = %w(Christian Teaching Jesus God Sermon Message)

    channel.itunes_subtitle = "Listen to practical, down-to-earth messages that will help you make a fresh start with God."
    channel.itunes_summary = "Daybreak Church delivers messages that are down-to-earth and relative to your life."

    #channel.itunes_image = RSS::ITunesChannelModel::ITunesImage.new("/path/to/logo.png") #TODO: itunes album art
    channel.itunes_explicit = "Clean"
		channel.generator = "Radiant CMS + MessagesExtension"
		channel.webMaster = "webmaster@daybreakweb.com"

		self.latest_feed.each do |message|
			channel.lastBuildDate ||= message.updated_at || message.created_at

			audio_type  = MIME::Types.type_for(message.audio).to_s


      item = RSS::Rss::Channel::Item.new
      item.title = message.title
      item.link = Radiant::Config['org.root_url'] + message.public_audio_file
      #audio_size  = File.size?(message.public_audio_file) #TODO: not resolving
      audio_size  = File.size?(message.audio) #TODO: not resolving
      #item.itunes_keywords = %w(Keywords For This Particular Audio Clip)
      item.guid = RSS::Rss::Channel::Item::Guid.new
      item.guid.content = item.link
      item.guid.isPermaLink = true
      item.pubDate = message.updated_at || message.created_at
      item.description = message.series.description rescue nil
			#text "<b>Delivered on: </b> #{message.delivered_on}<br />" + (message.delivered_by ? "<b>Delivered by:</b> #{message.delivered_by}<br />" : "") + (message.series ? "<b>From Series:</b> #{message.series.title}<br />" : "") + message.description + "<br />"
      item.itunes_summary = message.series.description rescue nil
      item.itunes_subtitle = "from the #{message.series.title} series" rescue nil
      item.itunes_explicit = "No"
      item.itunes_author = author

      # TODO can add duration once we can compute that somehow

      item.enclosure = RSS::Rss::Channel::Item::Enclosure.new(item.link, audio_size, audio_type)
      channel.items << item
    end

    rss.channel = channel
    return rss.to_s
  end
end

