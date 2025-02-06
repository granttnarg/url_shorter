require 'httparty'
require 'nokogiri'

class UrlMetaDataService < ApplicationService
  include HTTParty

  def self.fetch_metadata_for(url)
    options = headers

    doc = Nokogiri::HTML(HTTParty.get(url, options))

    {
      title: doc.at_css('title')&.text,
      description: doc.at_css('meta[name="description"]')&.attr('content')
    }

  rescue StandardError => e
      Rails.logger.error("Metadata fetch failed for #{url}: #{e.message}")
      { error: "Failed to fetch metadata" }
  end

  private

  def self.headers
    {
      headers: {
        'Accept-Language' => 'en-US,en;q=0.5',
        'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9'
      },
      follow_redirects: true,
      max_retries: 3
    }
  end
end