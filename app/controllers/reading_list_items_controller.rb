class ReadingListItemsController < ApplicationController
  before_action :authenticate_user!

  def create
    @ebook = Ebook.find(params[:ebook_id])
    @item = current_user.reading_list_items.build(
      ebook: @ebook,
      status: params[:status] || "want_to_read"
    )

    if @item.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: ebook_path(@ebook) }
      end
    else
      redirect_back fallback_location: ebook_path(@ebook), alert: @item.errors.full_messages.first
    end
  end

  def update
    @item = current_user.reading_list_items.find(params[:id])
    @ebook = @item.ebook

    if @item.update(reading_list_item_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: ebook_path(@ebook) }
      end
    else
      redirect_back fallback_location: ebook_path(@ebook), alert: @item.errors.full_messages.first
    end
  end

  def destroy
    @item = current_user.reading_list_items.find(params[:id])
    @ebook = @item.ebook
    @item.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: ebook_path(@ebook) }
    end
  end

  private

  def reading_list_item_params
    params.require(:reading_list_item).permit(:status, :current_page)
  end
end
