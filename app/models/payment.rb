class Payment < ApplicationRecord
  belongs_to :order

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending completed failed] }
end
