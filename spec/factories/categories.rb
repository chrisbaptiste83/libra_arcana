FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "#{Faker::Book.genre} #{n}" }
    description { Faker::Lorem.sentence }
    slug        { name.parameterize }
    icon        { "📚" }
  end
end
