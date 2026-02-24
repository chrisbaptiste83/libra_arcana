#!/usr/bin/env ruby
# frozen_string_literal: true

require "tempfile"
require "tmpdir"
require "open3"
require "vips"

delete_mock = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DELETE_MOCK", "false"))
generate_covers = ActiveModel::Type::Boolean.new.cast(ENV.fetch("GENERATE_COVERS", "false"))
extract_metadata = ActiveModel::Type::Boolean.new.cast(ENV.fetch("EXTRACT_METADATA", "false"))
only_unknown_author = ActiveModel::Type::Boolean.new.cast(ENV.fetch("ONLY_UNKNOWN_AUTHOR", "true"))
scan_pages = ENV.fetch("COVER_SCAN_PAGES", "10").to_i
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

  def blank_cover?(png_path)
    image = Vips::Image.new_from_file(png_path, access: :sequential)
    if image.width > 200
      image = image.resize(200.0 / image.width)
    end
    avg = image.avg
    avg > 250.0
  end

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

        Dir.mktmpdir("cover") do |dir|
          selected = nil
          (1..scan_pages).each do |page|
            prefix = File.join(dir, "page-#{page}")
            png_path = "#{prefix}.png"
            cmd = ["pdftoppm", "-f", page.to_s, "-l", page.to_s, "-png", "-singlefile", pdf_tmp.path, prefix]
            _out, err, status = Open3.capture3(*cmd)
            unless status.success? && File.exist?(png_path) && File.size?(png_path)
              raise "pdftoppm failed (exit=#{status.exitstatus}) cmd=#{cmd.join(' ')} err=#{err.strip}"
            end

            if blank_cover?(png_path)
              File.delete(png_path) if File.exist?(png_path)
              next
            end

            selected = png_path
            break
          end

          if selected
            ebook.cover_image.attach(
              io: File.open(selected, "rb"),
              filename: "#{ebook.title.parameterize}-cover.png",
              content_type: "image/png"
            )
            processed += 1
            puts "COVER: #{ebook.title}"
          else
            skipped += 1
            puts "SKIP (blank): #{ebook.title}"
          end
        end
      end
    rescue => e
      errors += 1
      warn "ERROR: #{ebook.title} - #{e.class}: #{e.message}"
    end
  end

  puts "Done. processed=#{processed} skipped=#{skipped} errors=#{errors}"
end

if extract_metadata
  scope = Ebook.all
  scope = scope.limit(limit) if limit&.positive?
  puts "Extracting PDF metadata for #{scope.count} ebooks..."

  updated = 0
  skipped = 0
  errors = 0

  scope.find_each do |ebook|
    unless ebook.ebook_file.attached? && ebook.ebook_file.content_type&.include?("pdf")
      skipped += 1
      next
    end

    if only_unknown_author
      current = ebook.author.to_s.strip
      next unless current.empty? || current.casecmp("unknown").zero?
    end

    begin
      Tempfile.create(["ebook", ".pdf"]) do |pdf_tmp|
        pdf_tmp.binmode
        pdf_tmp.write(ebook.ebook_file.download)
        pdf_tmp.flush

        out, err, status = Open3.capture3("pdfinfo", pdf_tmp.path)
        unless status.success?
          raise "pdfinfo failed: #{err.strip}"
        end

        line = out.lines.find { |l| l.start_with?("Author:") }
        author = line&.split("Author:", 2)&.last&.strip
        if author && !author.empty? && author.casecmp("unknown").nonzero?
          ebook.update!(author: author)
          updated += 1
          puts "AUTHOR: #{ebook.title} => #{author}"
        else
          skipped += 1
        end
      end
    rescue => e
      errors += 1
      warn "ERROR: #{ebook.title} - #{e.class}: #{e.message}"
    end
  end

  puts "Done. updated=#{updated} skipped=#{skipped} errors=#{errors}"
end

if !delete_mock && !generate_covers && !extract_metadata
  puts "Nothing to do. Set DELETE_MOCK=true and/or GENERATE_COVERS=true and/or EXTRACT_METADATA=true."
end
