FactoryBot.define do
  factory :ride_membership do
    association :ride
    association :user
    role   { 'rider' }
    status { 'active' }
  end
end
