namespace :storage do
  desc <<~DESC
    Delete ebooks (and their attached storage files) except those specified in KEEP_IDS.
    Set DRY_RUN=false to actually delete. Defaults to a safe dry run.

    Examples:
      # Preview what would be deleted (safe, no changes):
      bin/rails storage:cleanup KEEP_IDS=3,7,12

      # Actually delete everything except IDs 3, 7, and 12:
      bin/rails storage:cleanup KEEP_IDS=3,7,12 DRY_RUN=false

      # See all ebooks and their IDs first:
      bin/rails storage:list
  DESC
  task cleanup: :environment do
    dry_run = ENV.fetch("DRY_RUN", "true") != "false"
    keep_ids = ENV["KEEP_IDS"].to_s.split(",").map(&:strip).map(&:to_i).reject(&:zero?)

    if keep_ids.empty?
      puts "ERROR: KEEP_IDS is required. Provide a comma-separated list of Ebook IDs to keep."
      puts "  Example: bin/rails storage:cleanup KEEP_IDS=3,7,12"
      puts ""
      puts "Run `bin/rails storage:list` to see all ebooks and their IDs."
      exit 1
    end

    to_delete = Ebook.where.not(id: keep_ids)
    total     = Ebook.count
    keeping   = Ebook.where(id: keep_ids).count

    puts ""
    puts "=== storage:cleanup #{"[DRY RUN] " if dry_run}==="
    puts "  Total ebooks : #{total}"
    puts "  Keeping IDs  : #{keep_ids.join(", ")}"
    puts "  Keeping      : #{keeping}"
    puts "  Deleting     : #{to_delete.count}"
    puts ""

    if to_delete.none?
      puts "Nothing to delete."
      exit 0
    end

    to_delete.each do |ebook|
      cover_info = ebook.cover_image.attached? ? ebook.cover_image.filename.to_s : "none"
      file_info  = ebook.ebook_file.attached?  ? ebook.ebook_file.filename.to_s  : "none"
      puts "  [#{ebook.id}] #{ebook.title}"
      puts "        cover : #{cover_info}"
      puts "        file  : #{file_info}"

      unless dry_run
        ebook.cover_image.purge if ebook.cover_image.attached?
        ebook.ebook_file.purge  if ebook.ebook_file.attached?
        ebook.destroy!
        puts "        => DELETED"
      end
    end

    puts ""
    if dry_run
      puts "Dry run complete. No changes made."
      puts "Re-run with DRY_RUN=false to apply deletions."
    else
      puts "Done. #{to_delete.count} ebook(s) and their storage files deleted."
    end
  end

  desc "List all ebooks with their IDs, titles, and attached file sizes"
  task list: :environment do
    ebooks = Ebook.includes(:cover_image_attachment, :ebook_file_attachment).order(:id)

    puts ""
    puts "%-6s %-50s %-15s %-15s" % %w[ID Title Cover File]
    puts "-" * 90

    ebooks.each do |ebook|
      cover = ebook.cover_image.attached? ? ebook.cover_image.filename.to_s : "(none)"
      file  = ebook.ebook_file.attached?  ? ebook.ebook_file.filename.to_s  : "(none)"
      puts "%-6s %-50s %-15s %-15s" % [ebook.id, ebook.title.to_s.truncate(48), cover.truncate(13), file.truncate(13)]
    end

    puts ""
    puts "Total: #{ebooks.count} ebook(s)"
  end
end
