require 'factory_girl'

FactoryGirl.define do
  factory :image do
    factory :public_image do
      before(:create) { AdminPolicy.ensure_admin_policy_exists }
      admin_policy_id AdminPolicy::PUBLIC_POLICY_ID
    end

    trait :restricted do
      admin_policy_id AdminPolicy::RESTRICTED_POLICY_ID
    end

    trait :discovery do
      admin_policy_id AdminPolicy::DISCOVERY_POLICY_ID
    end
  end
end
