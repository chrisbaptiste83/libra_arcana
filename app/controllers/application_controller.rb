class ApplicationController < ActionController::Base
  include Pagy::Backend
  allow_browser versions: :modern

  helper_method :cart_count

  private

  def cart_count
    cart = session[:cart] || {}
    cart.keys.size
  end

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "You are not authorized to access that page."
    end
  end
end
