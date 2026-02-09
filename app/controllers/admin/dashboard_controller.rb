class Admin::DashboardController < Admin::BaseController
  def show
    @total_revenue = Payment.where(status: "completed").sum(:amount)
    @total_orders = Order.completed.count
    @total_users = User.count
    @total_ebooks = Ebook.count
    @recent_orders = Order.completed.recent.includes(:user, order_items: :ebook).limit(10)
    @top_ebooks = Ebook.joins(:order_items)
                       .select("ebooks.*, COUNT(order_items.id) as sales_count")
                       .group("ebooks.id")
                       .order("sales_count DESC")
                       .limit(5)
    @monthly_revenue = Payment.where(status: "completed")
                              .where("created_at >= ?", 30.days.ago)
                              .sum(:amount)
  end
end
