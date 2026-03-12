class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @favorites = current_user.favorites.includes(:ebook).order(created_at: :desc)
    @reading_list_items = current_user.reading_list_items.includes(:ebook).order(updated_at: :desc)
    @currently_reading = @reading_list_items.select { |i| i.status == "currently_reading" }
    @want_to_read = @reading_list_items.select { |i| i.status == "want_to_read" }
    @completed = @reading_list_items.select { |i| i.status == "completed" }
  end
end
