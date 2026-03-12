FactoryBot.define do
  factory :ebook do
    title            { Faker::Book.title }
    author           { Faker::Book.author }
    description      { Faker::Lorem.paragraph }
    language         { "English" }
    publication_year { Faker::Number.between(from: 1800, to: 2024) }
    featured         { false }
    association      :category

    trait :featured do
      featured { true }
    end
  end
end
