class HomeController < ApplicationController
  def index
    @featured_ebooks = Ebook.featured.includes(:category).order(created_at: :desc).limit(8)
    @categories = Category.all.order(:name)
  end
end
