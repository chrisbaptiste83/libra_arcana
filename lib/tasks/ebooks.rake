namespace :ebooks do
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
        puts "  [SKIP] #{ebook.title} — no PDF attached"
        next
      end

      puts "  [#{ebook.id}] #{ebook.title}"

      Dir.mktmpdir do |tmpdir|
        pdf_path = File.join(tmpdir, "ebook.pdf")

        # Download PDF from Active Storage
        File.open(pdf_path, "wb") do |f|
          ebook.ebook_file.download { |chunk| f.write(chunk) }
        end

        # Render first 3 pages to PNG (requires poppler-utils / pdftoppm)
        page_prefix = File.join(tmpdir, "page")
        system("pdftoppm", "-png", "-r", "100", "-l", "3", pdf_path, page_prefix)

        page_files = Dir.glob("#{page_prefix}*.png").sort.first(3)

        if page_files.empty?
          puts "    [WARN] pdftoppm produced no images — skipping"
          next
        end

        # Build vision content blocks from page images
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
end
