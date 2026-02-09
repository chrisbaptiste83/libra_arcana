class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :ebook

  validates :unit_price, presence: true, numericality: { greater_than: 0 }
end
