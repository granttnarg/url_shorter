class UrlController < ApplicationController
  def show
    @url = Url.find_by_slug(params[:id])
    if @url.nil? || !@url.is_valid_url?
      not_found
    else
      page = url.original
    end

    redirect_to page, allow_other_host: true
  end

  private

  def not_found
    raise ActionController::RoutingError.new('Url Not Found')
  end
end