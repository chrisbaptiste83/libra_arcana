class Admin::OrdersController < Admin::BaseController
  def index
    @pagy, @orders = pagy(
      Order.includes(:user, :payment, order_items: :ebook).order(created_at: :desc)
    )
  end

  def show
    @order = Order.includes(:user, :payment, order_items: :ebook).find(params[:id])
  end

  def update
    @order = Order.find(params[:id])
    if @order.update(order_params)
      redirect_to admin_order_path(@order), notice: "Order updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def order_params
    params.require(:order).permit(:status)
  end
end
