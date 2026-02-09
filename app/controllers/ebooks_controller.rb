class EbooksController < ApplicationController
  def index
    ebooks = Ebook.includes(:category)
    ebooks = ebooks.search(params[:search]) if params[:search].present?
    ebooks = ebooks.by_category(params[:category_id]) if params[:category_id].present?

    ebooks = case params[:sort]
    when "price_asc"
      ebooks.order(price: :asc)
    when "price_desc"
      ebooks.order(price: :desc)
    when "title"
      ebooks.order(title: :asc)
    when "newest"
      ebooks.order(created_at: :desc)
    else
      ebooks.order(created_at: :desc)
    end

    @pagy, @ebooks = pagy(ebooks)
    @categories = Category.order(:name)
  end

  def show
    @ebook = Ebook.find(params[:id])
    @related_ebooks = Ebook.where(category_id: @ebook.category_id)
                          .where.not(id: @ebook.id)
                          .limit(4)
  end
end
