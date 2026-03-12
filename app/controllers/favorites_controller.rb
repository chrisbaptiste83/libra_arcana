class FavoritesController < ApplicationController
  before_action :authenticate_user!

  def create
    @ebook = Ebook.find(params[:ebook_id])
    @favorite = current_user.favorites.build(ebook: @ebook)

    if @favorite.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: ebook_path(@ebook) }
      end
    else
      redirect_back fallback_location: ebook_path(@ebook), alert: @favorite.errors.full_messages.first
    end
  end

  def destroy
    @favorite = current_user.favorites.find(params[:id])
    @ebook = @favorite.ebook
    @favorite.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: ebook_path(@ebook) }
    end
  end
end
