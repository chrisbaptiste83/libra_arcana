class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :ebook

  validates :ebook_id, uniqueness: { scope: :user_id, message: "already in your favorites" }
end
