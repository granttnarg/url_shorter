class Url < ApplicationRecord
  before_validation :generate_slug
  before_save :set_url_expiry

  SLUG_LENGTH = (6..10).freeze
  EXPIRY_LENGTH_DAYS = 365.freeze
  CHAR_SET = [('a'..'z'), ('A'..'Z'), (0..9)].map(&:to_a).push('-').flatten

  validates :original, presence: true
  validate :validate_url_format
  validates :slug, presence: true, uniqueness: true, length:
                    {
                      minimum: SLUG_LENGTH.first,
                      maximum: SLUG_LENGTH.last,
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

  def valid_url?
      uri = URI.parse(original)
      uri.is_a?(URI::HTTP) &&!uri.host.nil?
    rescue URI::InvalidURIError
      false
  end

  def self.app_path_blacklist
    Rails.application.routes.routes.map do |route|
      route.path.spec.to_s.split('(').first.delete_prefix('/')
    end.select do |string|
      SLUG_LENGTH.include?(string.length) && !string.include?('/')
    end
  end

  private

  def set_url_expiry
    self.expired_at = EXPIRY_LENGTH_DAYS.days.from_now
  end

  def validate_url_format
    errors.add(:original, "url is not valid") unless valid_url?
  end

  def generate_slug
    return unless slug.nil?

    self.class.transaction do
      self.is_custom = false

      5.times do |i|
        self.slug = SecureRandom.send(:choose, CHAR_SET, 6)
        return if self.class.where(slug: slug ).none?
      end
    end
    errors.add(:slug, "couldn't generate unique slug after 5 attempts ")
  end

  def url_not_blacklisted
    errors.add(:slug, "Url taken please try again") if Url.app_path_blacklist.include?(self.slug)
  end
end

