FactoryBot.define do
  factory :ride do
    association :leader, factory: :user
    sequence(:name)      { |n| "Ride #{n}" }
    sequence(:public_id) { |n| "RID-T#{n.to_s.rjust(3, '0')}" }
    status { 'active' }
    auto_approve { false }
  end
end
