FactoryBot.define do
  factory :user do
    sequence(:email)    { |n| "rider#{n}@example.com" }
    sequence(:username) { |n| "rider#{n}" }
    sequence(:name)     { |n| "Rider #{n}" }
    password_digest { BCrypt::Password.create('password123') }
  end
end
