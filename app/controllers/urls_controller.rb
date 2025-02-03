class UrlsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :index, :show]

  def redirect
    @url = find_url
    if @url.nil? || !@url.valid_url?
      not_found
    else
      page = @url.original
    end

    redirect_to page, allow_other_host: true
  end

  def index;
    @urls = Url.all
  end

  def show
    @url = find_url
  end

  def new
    @url = Url.new
  end

  def create
    @url = Url.new(url_params)

    if @url.save
      redirect_to url_path(@url), notice: 'URL was successfully created'
    else
      render :new, status: :unprocessable_entity, notice: "Url Generation Failed"
    end
  end

  def url_params
    params.require(:url).permit(:original, :slug).reject { |_, v| v.blank? }
  end

  private

  def find_url
    Url.find_by_slug!(params[:id])
  end

  def not_found
    raise ActionController::RoutingError.new('Url Not Found')
  end
end
