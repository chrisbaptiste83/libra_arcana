class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :favorites, dependent: :destroy
  has_many :favorited_ebooks, through: :favorites, source: :ebook

  has_many :reading_list_items, dependent: :destroy
  has_many :reading_list_ebooks, through: :reading_list_items, source: :ebook

  validates :first_name, presence: true
  validates :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def favorited?(ebook)
    favorited_ebooks.include?(ebook)
  end

  def reading_list_item_for(ebook)
    reading_list_items.find_by(ebook: ebook)
  end
end
