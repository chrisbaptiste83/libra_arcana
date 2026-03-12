FactoryBot.define do
  factory :favorite do
    association :user
    association :ebook
  end
end
