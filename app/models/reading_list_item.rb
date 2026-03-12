class ReadingListItem < ApplicationRecord
  STATUSES = %w[want_to_read currently_reading completed].freeze

  belongs_to :user
  belongs_to :ebook

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :ebook_id, uniqueness: { scope: :user_id, message: "already on your reading list" }

  scope :want_to_read, -> { where(status: "want_to_read") }
  scope :currently_reading, -> { where(status: "currently_reading") }
  scope :completed, -> { where(status: "completed") }

  def status_label
    status.humanize
  end
end
