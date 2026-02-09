class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_one :payment, dependent: :destroy
  has_many :download_accesses, dependent: :destroy

  validates :status, inclusion: { in: %w[pending completed failed] }

  scope :completed, -> { where(status: "completed") }
  scope :recent, -> { order(created_at: :desc) }
end
