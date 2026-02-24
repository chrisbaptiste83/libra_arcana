#!/usr/bin/env ruby
# frozen_string_literal: true

require "active_support/core_ext/string/inflections"
require "marcel"

import_dir = ENV.fetch("IMPORT_DIR", "/tmp/ebooks_import")
price_base = ENV.fetch("IMPORT_PRICE_BASE", "9.99").to_f
price_per_10mb = ENV.fetch("IMPORT_PRICE_PER_10MB", "1.0").to_f
price_cap = ENV.fetch("IMPORT_PRICE_CAP", "29.99").to_f
author_default = ENV.fetch("IMPORT_AUTHOR_DEFAULT", "Unknown")
featured_default = ActiveModel::Type::Boolean.new.cast(ENV.fetch("IMPORT_FEATURED", "false"))
dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch("IMPORT_DRY_RUN", "false"))

unless Dir.exist?(import_dir)
  warn "Import dir not found: #{import_dir}"
  exit 1
end

def price_for_bytes(bytes, base:, per_10mb:, cap:)
  size_mb = bytes.to_f / (1024 * 1024)
  increments = (size_mb / 10.0).ceil
  price = base + (increments * per_10mb)
  [price, cap].min.round(2)
end

paths = Dir.glob(File.join(import_dir, "**", "*.{pdf,epub,PDF,EPUB}"))
puts "Found #{paths.size} ebook files under #{import_dir}"

created = 0
skipped = 0
attached = 0
errors = 0

paths.each do |path|
  rel = path.delete_prefix("#{import_dir}/")
  parts = rel.split("/")
  category_name = parts.length > 1 ? parts.first.tr("_-", " ").titleize : "Uncategorized"
  filename = File.basename(path)
  title_base = File.basename(filename, File.extname(filename)).tr("_-", " ").squeeze(" ").strip
  title = title_base.titleize

  category = Category.find_or_create_by!(name: category_name)
  ebook = Ebook.find_by(title: title, category_id: category.id)

  if ebook&.ebook_file&.attached?
    skipped += 1
    puts "SKIP: #{title} (#{category.name}) already attached"
    next
  end

  bytes = File.size(path)
  price = price_for_bytes(bytes, base: price_base, per_10mb: price_per_10mb, cap: price_cap)
  description = "Imported from S3. Category: #{category.name}."

  if dry_run
    puts "DRY RUN: #{title} (#{category.name}) $#{price} from #{rel}"
    next
  end

  begin
    ebook ||= Ebook.new(
      title: title,
      author: author_default,
      price: price,
      description: description,
      featured: featured_default,
      category: category
    )

    ebook.save! if ebook.new_record?

    content_type = Marcel::MimeType.for(Pathname.new(path))
    ebook.ebook_file.attach(
      io: File.open(path, "rb"),
      filename: filename,
      content_type: content_type
    )
    attached += 1
    created += 1 if ebook.previous_changes.key?("id")
    puts "IMPORTED: #{title} (#{category.name}) $#{price} from #{rel}"
  rescue => e
    errors += 1
    warn "ERROR: #{title} (#{category.name}) - #{e.class}: #{e.message}"
  end
end

puts "Done. created=#{created} attached=#{attached} skipped=#{skipped} errors=#{errors}"
