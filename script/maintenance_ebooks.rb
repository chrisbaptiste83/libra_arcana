#!/usr/bin/env ruby
# frozen_string_literal: true

require "tempfile"
require "open3"

delete_mock = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DELETE_MOCK", "false"))
generate_covers = ActiveModel::Type::Boolean.new.cast(ENV.fetch("GENERATE_COVERS", "false"))
limit = ENV["LIMIT"]&.to_i

if delete_mock
  mock_scope = Ebook.left_outer_joins(:ebook_file_attachment).where(active_storage_attachments: { id: nil })
  mock_scope = mock_scope.limit(limit) if limit&.positive?
  count = mock_scope.count
  puts "Deleting #{count} ebooks without attached file..."
  mock_scope.find_each do |ebook|
    ebook.destroy!
  end
  puts "Deleted #{count} ebooks."
end

if generate_covers
  scope = Ebook.left_outer_joins(:cover_image_attachment).where(active_storage_attachments: { id: nil })
  scope = scope.limit(limit) if limit&.positive?
  puts "Generating covers for #{scope.count} ebooks without cover..."

  processed = 0
  skipped = 0
  errors = 0

  scope.find_each do |ebook|
    unless ebook.ebook_file.attached?
      skipped += 1
      next
    end

    unless ebook.ebook_file.content_type&.include?("pdf")
      skipped += 1
      next
    end

    begin
      Tempfile.create(["ebook", ".pdf"]) do |pdf_tmp|
        pdf_tmp.binmode
        pdf_tmp.write(ebook.ebook_file.download)
        pdf_tmp.flush

        Tempfile.create(["cover", ""]) do |cover_tmp|
          cover_tmp.close
          png_path = "#{cover_tmp.path}-1.png"

          cmd = ["pdftoppm", "-f", "1", "-l", "1", "-png", pdf_tmp.path, cover_tmp.path]
          _out, err, status = Open3.capture3(*cmd)
          unless status.success? && File.exist?(png_path)
            raise "pdftoppm failed: #{err}"
          end

          ebook.cover_image.attach(
            io: File.open(png_path, "rb"),
            filename: "#{ebook.title.parameterize}-cover.png",
            content_type: "image/png"
          )
        ensure
          File.delete(png_path) if png_path && File.exist?(png_path)
        end
      end

      processed += 1
      puts "COVER: #{ebook.title}"
    rescue => e
      errors += 1
      warn "ERROR: #{ebook.title} - #{e.class}: #{e.message}"
    end
  end

  puts "Done. processed=#{processed} skipped=#{skipped} errors=#{errors}"
end

if !delete_mock && !generate_covers
  puts "Nothing to do. Set DELETE_MOCK=true and/or GENERATE_COVERS=true."
end
