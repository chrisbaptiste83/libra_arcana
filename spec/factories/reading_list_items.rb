FactoryBot.define do
  factory :reading_list_item do
    association :user
    association :ebook
    status { "want_to_read" }

    trait :currently_reading do
      status { "currently_reading" }
      current_page { Faker::Number.between(from: 1, to: 200) }
    end

    trait :completed do
      status { "completed" }
    end
  end
end
