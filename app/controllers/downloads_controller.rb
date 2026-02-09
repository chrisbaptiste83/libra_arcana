class DownloadsController < ApplicationController
  before_action :authenticate_user!

  def show
    @download_access = DownloadAccess.find_by!(access_token: params[:token])

    if @download_access.expired?
      redirect_to dashboard_library_path, alert: "Download link has expired."
      return
    end

    if @download_access.user != current_user
      redirect_to root_path, alert: "Unauthorized access."
      return
    end

    @download_access.increment!(:download_count)

    if @download_access.ebook&.ebook_file&.attached?
      redirect_to rails_blob_url(@download_access.ebook.ebook_file, disposition: "attachment", only_path: false)
    else
      redirect_to dashboard_library_path, alert: "File not available for download."
    end
  end
end
