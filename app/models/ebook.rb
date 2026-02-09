class Ebook < ApplicationRecord
  belongs_to :category
  has_many :order_items, dependent: :restrict_with_error
  has_many :download_accesses, dependent: :destroy

  has_one_attached :cover_image
  has_one_attached :ebook_file

  validates :title, presence: true
  validates :author, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true

  scope :featured, -> { where(featured: true) }
  scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :search, ->(query) {
    where("title LIKE ? OR author LIKE ? OR description LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%") if query.present?
  }

  def formatted_price
    "$#{'%.2f' % price}"
  end
end
