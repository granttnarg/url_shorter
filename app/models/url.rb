class Url < ApplicationRecord
  before_validation :set_slug
  before_save :set_url_expiry

  validates :original, presence: true
  validate :validate_url_format
  validates :slug, presence: true, uniqueness: true, length:
                    {
                      minimum: UrlShortenerService::SLUG_LENGTH.first,
                      maximum: UrlShortenerService::SLUG_LENGTH.last,
                      too_short: 'custom url path must be 6 or more characters but less than 10',
                      too_long: 'custom url path must be 10 or less character but more than 6'
                    },
            format:
                  {
                    with: /\A[a-zA-Z0-9-]+\z/,
                    message: 'can only contain upper and lower case letters, numbers or hyphens'
                    }

  validate :url_not_blacklisted


  def to_param
    slug
  end

  def set_slug
    return if slug.present?

    service = UrlShortenerService.new(self)
    begin
      service.generate_slug
    rescue UrlShortenerService::SlugGenerationError => e
      errors.add(:slug, e.message)
    end
  end

  def set_url_expiry
    UrlShortenerService.new(self).set_expiry
  end

  private

  def valid_url?
      uri = URI.parse(original)
      uri.is_a?(URI::HTTP) &&!uri.host.nil?
    rescue URI::InvalidURIError
      false
  end

  def validate_url_format
    errors.add(:original, "url is not valid") unless valid_url?
  end

  def url_not_blacklisted
    service = UrlShortenerService.new(self)
    errors.add(:slug, "Url taken please try again") if service.blacklisted?(slug)
  end
end

