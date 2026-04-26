class ApplicationController < ActionController::Base
  include Pagy::Method
  allow_browser versions: :modern

  before_action :set_nav_categories

  private

  def set_nav_categories
    @nav_categories = Category.joins(:ebooks).distinct.order(:name)
  end

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "You are not authorized to access that page."
    end
  end
end
