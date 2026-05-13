class Admin::PipelineController < Admin::BaseController
  def show
    total         = Ebook.count
    with_file     = Ebook.joins(:ebook_file_attachment).count
    with_cover    = Ebook.joins(:cover_image_attachment).count
    with_ai_desc  = Ebook.where.not(description: [ nil, "" ])
                         .where("description NOT LIKE ?", "Imported from S3%")
                         .count

    @stats = {
      total:        total,
      with_file:    with_file,
      without_file: total - with_file,
      with_cover:   with_cover,
      without_cover: total - with_cover,
      with_desc:    with_ai_desc,
      without_desc: total - with_ai_desc
    }

    @by_category = Category.left_joins(:ebooks)
                           .joins("LEFT JOIN active_storage_attachments ebook_files
                                   ON ebook_files.record_type = 'Ebook'
                                   AND ebook_files.record_id = ebooks.id
                                   AND ebook_files.name = 'ebook_file'")
                           .joins("LEFT JOIN active_storage_attachments covers
                                   ON covers.record_type = 'Ebook'
                                   AND covers.record_id = ebooks.id
                                   AND covers.name = 'cover_image'")
                           .select(
                             "categories.id, categories.name,
                              COUNT(DISTINCT ebooks.id) AS ebook_count,
                              COUNT(DISTINCT ebook_files.id) AS file_count,
                              COUNT(DISTINCT covers.id) AS cover_count"
                           )
                           .group("categories.id, categories.name")
                           .order("ebook_count DESC")

    @recent = Ebook.includes(:category, :cover_image_attachment, :ebook_file_attachment)
                   .order(created_at: :desc)
                   .limit(20)
  end
end
