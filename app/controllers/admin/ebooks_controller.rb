class Admin::EbooksController < Admin::BaseController
  before_action :set_ebook, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @ebooks = pagy(Ebook.includes(:category).order(created_at: :desc))
  end

  def show
  end

  def new
    @ebook = Ebook.new
  end

  def create
    @ebook = Ebook.new(ebook_params)

    if @ebook.save
      redirect_to admin_ebook_path(@ebook), notice: "Ebook created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @ebook.update(ebook_params)
      redirect_to admin_ebook_path(@ebook), notice: "Ebook updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @ebook.destroy
      redirect_to admin_ebooks_path, notice: "Ebook deleted successfully."
    else
      redirect_to admin_ebooks_path, alert: "Cannot delete ebook: #{@ebook.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_ebook
    @ebook = Ebook.find(params[:id])
  end

  def ebook_params
    params.require(:ebook).permit(
      :title, :author, :price, :description, :page_count,
      :isbn, :language, :publication_year, :featured,
      :category_id, :cover_image, :ebook_file
    )
  end
end
