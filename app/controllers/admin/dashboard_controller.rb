class Admin::DashboardController < Admin::BaseController
  def show
    @total_users = User.count
    @total_ebooks = Ebook.count
    @total_categories = Category.count
    @recent_ebooks = Ebook.includes(:category).order(created_at: :desc).limit(10)
    @featured_ebooks_count = Ebook.featured.count
    @popular_categories = Category.left_joins(:ebooks)
                                  .select("categories.*, COUNT(ebooks.id) as ebooks_count")
                                  .group("categories.id")
                                  .order("ebooks_count DESC")
                                  .limit(6)
  end
end
