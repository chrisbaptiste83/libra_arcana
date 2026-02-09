class Admin::UsersController < Admin::BaseController
  def index
    @pagy, @users = pagy(User.order(created_at: :desc))
  end

  def show
    @user = User.find(params[:id])
    @orders = @user.orders.recent.includes(order_items: :ebook)
  end
end
