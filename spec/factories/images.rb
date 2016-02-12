require 'factory_girl'

FactoryGirl.define do
  factory :image do
    title ['Test Image']
    identifier { [Time.now.strftime('%m%d%Y%M%S') + rand(1_000_000).to_s] }
    factory :public_image do
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
