require "factory_girl"
FactoryGirl.define do
  factory :scanned_map do
    sequence(:title) { |n| ["Scanned Map #{n}"] }
    factory :public_scanned_map do
      admin_policy_id AdminPolicy::PUBLIC_POLICY_ID
    end
  end

  factory :index_map do
    sequence(:title) { |n| ["Index Map #{n}"] }
    factory :public_index_map do
      admin_policy_id AdminPolicy::PUBLIC_POLICY_ID
    end
  end

  factory :component_map do
    sequence(:title) { |n| ["Component Map #{n}"] }
    factory :public_component_map do
      admin_policy_id AdminPolicy::PUBLIC_POLICY_ID
    end
  end

  factory :map_set do
    sequence(:title) { |n| ["Map Set #{n}"] }
    factory :public_map_set do
      admin_policy_id AdminPolicy::PUBLIC_POLICY_ID
    end
  end
end
