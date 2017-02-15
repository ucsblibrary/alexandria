require "factory_girl"
FactoryGirl.define do
  factory :scanned_map do
    sequence(:title) { |n| ["Scanned Map #{n}"] }
    factory :public_scanned_map do
      admin_policy_id AdminPolicy::PUBLIC_POLICY_ID
    end
  end
end
