class CategoriesController < ApplicationController
  def show
    @category = Category.find_by!(slug: params[:slug])
    @pagy, @ebooks = pagy(@category.ebooks.order(created_at: :desc))
  end
end
