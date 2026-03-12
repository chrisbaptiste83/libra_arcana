class Ebook < ApplicationRecord
  belongs_to :category
  has_one_attached :cover_image
  has_one_attached :ebook_file

  has_many :favorites, dependent: :destroy
  has_many :favorited_by_users, through: :favorites, source: :user

  has_many :reading_list_items, dependent: :destroy

  validates :title, presence: true
  validates :author, presence: true
  validates :description, presence: true

  scope :featured, -> { where(featured: true) }
  scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :search, ->(query) {
    where("title LIKE ? OR author LIKE ? OR description LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%") if query.present?
  }

end
