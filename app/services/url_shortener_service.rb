class UrlShortenerService < ApplicationService
  class SlugGenerationError < StandardError; end

  SLUG_LENGTH = (6..10).freeze
  SLUG_CHAR_SET = [('a'..'z'), ('A'..'Z'), (0..9)].map(&:to_a).push('-').flatten
  EXPIRY_LENGTH_DAYS = 365.freeze

  def initialize(url = nil)
    @url = url
  end

  def generate_slug
    return @url.slug if @url.slug.present?

    ActiveRecord::Base.transaction do
      @url.is_custom = false

      5.times do |i|
        candidate_slug = SecureRandom.send(:choose, SLUG_CHAR_SET, 6)
        if slug_available?(candidate_slug)
          @url.slug = candidate_slug
          @url.is_custom = false
          return candidate_slug
        end
      end
    end

    raise SlugGenerationError, "Couldn't generate unique slug after 5 attempts"
  end

  def slug_available?(slug)
    !Url.exists?(slug: slug) && !blacklisted?(slug)
  end

  def blacklisted?(slug)
    app_slug_blacklist.include?(slug)
  end

  def set_expiry
    @url.expires_at = EXPIRY_LENGTH_DAYS.days.from_now if @url.expires_at.nil?
  end

  private

  def app_slug_blacklist
    Rails.application.routes.routes.map do |route|
      route.path.spec.to_s.split('(').first.delete_prefix('/')
    end.select do |string|
      SLUG_LENGTH.include?(string.length) && !string.include?('/')
    end
  end
end