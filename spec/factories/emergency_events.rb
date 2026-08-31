FactoryBot.define do
  factory :emergency_event do
    association :ride
    association :user
    event_type { 'sos' }
    latitude   { 28.6139 }
    longitude  { 77.2090 }
  end
end
