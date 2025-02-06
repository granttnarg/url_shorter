class UrlMetaDataJob < ApplicationJob
  queue_as :default

  def perform(slug)
    url = Url.find_by_slug(slug)

    return if url.blank?

    unless SslCheckerService.check_ssl(url.original)[:valid?]
      Rails.logger.error("Metadata job failed for #{url.id}; unsafe url detected #{url.original}")
      return
    end

    result = UrlMetaDataService.fetch_metadata_for(url.original)

    if !result[:error].nil? || result[:title].nil? && result[:description].nil?
      Rails.logger.error("Metadata job failed for #{url.id}")
      return
    end

    url.update!(meta_title: result[:title], meta_description: result[:description])
    Rails.logger.info("Metadata job successful for #{url.id}")
  end
end
