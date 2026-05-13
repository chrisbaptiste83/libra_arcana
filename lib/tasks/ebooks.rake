namespace :ebooks do
  def ebooks_s3_client
    Aws::S3::Client.new(
      region: Rails.application.credentials.dig(:aws, :region),
      access_key_id: Rails.application.credentials.dig(:aws, :access_key_id),
      secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key)
    )
  end

  def ebooks_s3_copy_source(bucket_name, key)
    require "cgi"

    encoded_key = key.split("/").map { |part| CGI.escape(part) }.join("/")
    "#{bucket_name}/#{encoded_key}"
  end

  def move_s3_object(s3, bucket_name, from_key, to_key)
    return if from_key == to_key

    s3.copy_object(
      bucket: bucket_name,
      copy_source: ebooks_s3_copy_source(bucket_name, from_key),
      key: to_key
    )
    s3.delete_object(bucket: bucket_name, key: from_key)
  end

  desc "Generate AI descriptions for all ebooks using Claude vision on the PDF pages"
  task generate_descriptions: :environment do
    require "anthropic"
    require "tmpdir"
    require "base64"

    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    ebooks = Ebook.includes(:ebook_file_attachment).all
    puts "Processing #{ebooks.count} ebooks..."

    ebooks.each do |ebook|
      unless ebook.ebook_file.attached?
        puts "  [SKIP] #{ebook.title} - no ebook attached"
        next
      end

      blob = ebook.ebook_file.blob
      unless blob.content_type == "application/pdf" || blob.filename.extension_without_delimiter&.downcase == "pdf"
        puts "  [SKIP] #{ebook.title} - descriptions currently require a PDF"
        next
      end

      puts "  [#{ebook.id}] #{ebook.title}"

      Dir.mktmpdir do |tmpdir|
        pdf_path = File.join(tmpdir, "ebook.pdf")

        File.open(pdf_path, "wb") do |f|
          ebook.ebook_file.download { |chunk| f.write(chunk) }
        end

        page_prefix = File.join(tmpdir, "page")
        system("pdftoppm", "-png", "-r", "100", "-l", "10", pdf_path, page_prefix)

        page_files = Dir.glob("#{page_prefix}*.png").sort.first(10)

        if page_files.empty?
          puts "    [WARN] pdftoppm produced no images — skipping"
          next
        end

        image_blocks = page_files.map do |path|
          {
            type: "image",
            source: {
              type: "base64",
              media_type: "image/png",
              data: Base64.strict_encode64(File.binread(path))
            }
          }
        end

        prompt_block = {
          type: "text",
          text: <<~PROMPT
            These images are pages from an ebook titled "#{ebook.title}" by #{ebook.author}.
            Write a concise product description (2-4 sentences) for an online bookstore listing.
            Focus on the subject matter and what a reader will learn or experience.
            Do not mention scanning, image quality, or that this is a PDF.
            Reply with only the description text, no preamble.
          PROMPT
        }

        response = client.messages(
          model: "claude-opus-4-6",
          max_tokens: 512,
          messages: [
            {
              role: "user",
              content: image_blocks + [ prompt_block ]
            }
          ]
        )

        description = response.content.first.text.strip

        if description.present?
          ebook.update!(description: description)
          puts "    OK: #{description.truncate(80)}"
        else
          puts "    [WARN] Empty response from Claude"
        end
      end

    rescue => e
      puts "    [ERROR] #{e.class}: #{e.message}"
    end

    puts "Done."
  end

  desc "Move root-level and Classics/Texts PDFs into ebooks/raw/<category>/ using Claude"
  task :organize_s3_bucket, [ :bucket ] => :environment do |_t, args|
    require "anthropic"
    require "aws-sdk-s3"
    require "json"

    bucket_name = args[:bucket] || ENV.fetch("EBOOKS_S3_BUCKET", "libra-arcana-dev-assets")
    s3 = ebooks_s3_client
    ai = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    # Collect files not already under ebooks/raw/, ebooks/processed/, or active_storage/
    skip_prefixes = %w[ebooks/ active_storage/ covers/ embeddings/ logs/ metadata/]
    unorganized = []

    s3.list_objects_v2(bucket: bucket_name).each_page do |page|
      page.contents.each do |obj|
        next unless obj.key.match?(/\.(pdf|epub|doc)\z/i)
        next if skip_prefixes.any? { |p| obj.key.start_with?(p) }
        unorganized << obj.key
      end
    end

    if unorganized.empty?
      puts "Nothing to organize."
      next
    end

    puts "Found #{unorganized.size} unorganized file(s). Asking Claude for categories..."

    filenames = unorganized.map { |k| File.basename(k, ".*").tr("_-", " ").squeeze(" ").strip }

    # Process in batches of 50 to stay within token limits
    categories = {}
    filenames.each_slice(50) do |batch|
      response = ai.messages(
        model: "claude-opus-4-6",
        max_tokens: 2048,
        messages: [
          {
            role: "user",
            content: <<~PROMPT
              You are organizing an esoteric/philosophical digital library. The library's existing categories are:
              Ancient Language & Symbolism, Founding Fathers, Natural Law, Theosophy, Trivium, Classics, Primary Texts

              For each ebook filename below, choose the best matching category from the list above, or suggest a new short category name (Title Case, 2-4 words) if none fit.

              Reply ONLY with a JSON object mapping each filename exactly as given to a category name string. No explanation, no markdown fences, no extra text.

              Filenames:
              #{batch.join("\n")}
            PROMPT
          }
        ]
      )
      categories.merge!(JSON.parse(response.content.first.text.strip))
    end

    moved = 0
    unorganized.each do |key|
      display_name = File.basename(key, ".*").tr("_-", " ").squeeze(" ").strip
      category = categories[display_name]
      safe_category = category.to_s.tr("/", "-").squeeze(" ").strip

      if safe_category.blank?
        puts "  [SKIP] No category returned for: #{key}"
        next
      end

      new_key = "ebooks/raw/#{safe_category}/#{File.basename(key)}"
      puts "  #{key} -> #{new_key}"

      move_s3_object(s3, bucket_name, key, new_key)
      moved += 1
    rescue => e
      warn "  [ERROR] #{key} - #{e.class}: #{e.message}"
    end

    puts "Done. Moved #{moved}/#{unorganized.size} file(s) into ebooks/raw/<category>/."
  end

  desc "Import ebooks from s3://bucket/ebooks/raw/ and move them to ebooks/processed/ on success"
  task :import_from_s3, [ :bucket ] => :environment do |_t, args|
    require "aws-sdk-s3"
    require "tmpdir"
    require "marcel"
    require "open3"

    bucket_name    = args[:bucket] || ENV.fetch("EBOOKS_S3_BUCKET", "libra-arcana-dev-assets")
    raw_prefix     = "ebooks/raw/"
    processed_prefix = "ebooks/processed/"
    author_default = ENV.fetch("IMPORT_AUTHOR_DEFAULT", "Unknown")
    dry_run        = ActiveModel::Type::Boolean.new.cast(ENV.fetch("IMPORT_DRY_RUN", "false"))

    s3 = ebooks_s3_client

    created = 0; skipped = 0; moved = 0; errors = 0
    puts "Importing from s3://#{bucket_name}/#{raw_prefix}#{dry_run ? " [DRY RUN]" : ""}..."

    s3.list_objects_v2(bucket: bucket_name, prefix: raw_prefix).each_page do |page|
      page.contents.each do |obj|
        next unless obj.key.match?(/\.(pdf|epub)\z/i)

        # Strip the raw_prefix, then split into category/filename
        relative      = obj.key.delete_prefix(raw_prefix)
        parts         = relative.split("/")
        raw_category  = parts.length > 1 ? parts.first : "Uncategorized"

        # Normalize names like "Founding Fathers 1" to "Founding Fathers".
        category_name = raw_category.gsub(/\s+\d+\z/, "").strip

        filename = File.basename(obj.key)
        title    = File.basename(filename, ".*").tr("_-", " ").squeeze(" ").strip.titleize
        processed_key = "#{processed_prefix}#{relative}"

        category = Category.find_or_create_by!(name: category_name)
        ebook    = Ebook.find_by(title: title, category_id: category.id)

        if ebook&.ebook_file&.attached?
          skipped += 1
          puts "  SKIP: #{title} (#{category.name})"
          unless dry_run
            move_s3_object(s3, bucket_name, obj.key, processed_key)
            moved += 1
          end
          next
        end

        if dry_run
          puts "  DRY RUN: #{title} [#{category.name}] <- #{obj.key}"
          next
        end

        Dir.mktmpdir do |tmpdir|
          local_path = File.join(tmpdir, filename)
          s3.get_object(response_target: local_path, bucket: bucket_name, key: obj.key)

          out, _err, status = Open3.capture3("pdfinfo", local_path)
          author = nil
          if status.success?
            line   = out.lines.find { |l| l.start_with?("Author:") }
            raw    = line&.split("Author:", 2)&.last&.strip
            author = raw if raw && !raw.empty? && raw.downcase != "unknown"
          end
          author ||= author_default

          ebook ||= Ebook.new(
            title: title, author: author,
            description: "Imported from S3. Category: #{category.name}.",
            featured: false, category: category
          )
          ebook.save! if ebook.new_record?

          content_type = Marcel::MimeType.for(Pathname.new(local_path))
          ebook.ebook_file.attach(
            io: File.open(local_path, "rb"),
            filename: filename,
            content_type: content_type
          )

          # Generate cover: render pages 1–5, pick the one with the most visual content
          if obj.key.match?(/\.pdf\z/i) && !ebook.cover_image.attached?
            cover_prefix = File.join(tmpdir, "cover")
            if system("pdftoppm", "-png", "-r", "150", "-f", "1", "-l", "5",
                       local_path, cover_prefix, out: File::NULL, err: File::NULL)
              candidates = Dir.glob("#{cover_prefix}*.png").sort
              best = candidates.max_by { |f| File.size(f) }
              if best
                ebook.cover_image.attach(
                  io: File.open(best, "rb"),
                  filename: "cover_#{ebook.id}.png",
                  content_type: "image/png"
                )
                page_num = File.basename(best, ".png").scan(/\d+/).last.to_i
                puts "    COVER: page #{page_num} of #{candidates.size}"
              end
            end
          end

          move_s3_object(s3, bucket_name, obj.key, processed_key)
          created += 1
          moved += 1
          puts "  IMPORTED: #{title} (#{category.name})"
        end
      rescue => e
        errors += 1
        warn "  [ERROR] #{obj.key} - #{e.class}: #{e.message}"
      end
    end

    puts "Done. imported=#{created} skipped=#{skipped} moved=#{moved} errors=#{errors}"
  end

  desc "Generate cover images for ebooks (renders best of first 5 pages). FORCE=true to regenerate existing."
  task generate_covers: :environment do
    require "tmpdir"

    force = ActiveModel::Type::Boolean.new.cast(ENV.fetch("FORCE", "false"))

    ebooks = Ebook.includes(:ebook_file_attachment, :ebook_file_blob, :cover_image_attachment).all.select do |e|
      e.ebook_file.attached? &&
        (force || !e.cover_image.attached?) &&
        (e.ebook_file.blob.content_type == "application/pdf" ||
          e.ebook_file.blob.filename.extension_without_delimiter&.downcase == "pdf")
    end

    puts "Generating covers for #{ebooks.size} ebook(s)#{force ? ' [FORCE — replacing existing]' : ''}..."

    ebooks.each do |ebook|
      puts "  [#{ebook.id}] #{ebook.title}"
      Dir.mktmpdir do |tmpdir|
        pdf_path     = File.join(tmpdir, "ebook.pdf")
        cover_prefix = File.join(tmpdir, "cover")

        File.open(pdf_path, "wb") { |f| ebook.ebook_file.download { |chunk| f.write(chunk) } }

        # Render pages 1–5 at 150 DPI, then pick the one with the most visual content.
        # Largest PNG file size = most ink on the page, which reliably picks a title or
        # content page over blank/nearly-blank opening pages.
        unless system("pdftoppm", "-png", "-r", "150", "-f", "1", "-l", "5",
                      pdf_path, cover_prefix, out: File::NULL, err: File::NULL)
          puts "    [WARN] pdftoppm failed"
          next
        end

        candidates = Dir.glob("#{cover_prefix}*.png").sort
        if candidates.empty?
          puts "    [WARN] no pages produced"
          next
        end

        best = candidates.max_by { |f| File.size(f) }
        page_num = File.basename(best, ".png").scan(/\d+/).last.to_i

        ebook.cover_image.purge if force && ebook.cover_image.attached?
        ebook.cover_image.attach(
          io: File.open(best, "rb"),
          filename: "cover_#{ebook.id}.png",
          content_type: "image/png"
        )
        puts "    OK (used page #{page_num} of #{candidates.size} rendered, #{(File.size(best) / 1024.0).round}KB)"
      end
    rescue => e
      puts "    [ERROR] #{e.class}: #{e.message}"
    end

    puts "Done."
  end

  desc "Full pipeline: organize bucket -> import from S3 -> generate AI descriptions"
  task :full_pipeline, [ :bucket ] => :environment do |_t, args|
    bucket = args[:bucket] || ENV.fetch("EBOOKS_S3_BUCKET", "libra-arcana-dev-assets")
    Rake::Task["ebooks:organize_s3_bucket"].invoke(bucket)
    Rake::Task["ebooks:import_from_s3"].invoke(bucket)
    Rake::Task["ebooks:generate_descriptions"].invoke
  end
end
