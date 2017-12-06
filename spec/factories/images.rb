# frozen_string_literal: true

FactoryBot.define do
  factory :image do
    title ["Test Image"]

    identifier do
      [Time.zone.now.strftime("%m%d%Y%M%S") + rand(1_000_000).to_s]
    end

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
