class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @recent_orders = current_user.orders.completed.recent.limit(5).includes(order_items: :ebook)
    @download_count = current_user.download_accesses.active.count
    @total_spent = current_user.orders.completed.sum(:total)
    @total_orders = current_user.orders.completed.count
  end

  def library
    @download_accesses = current_user.download_accesses.active.includes(:ebook).order(created_at: :desc)
  end

  def orders
    @orders = current_user.orders.recent.includes(order_items: :ebook, payment: nil)
  end
end
