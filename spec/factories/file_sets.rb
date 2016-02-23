require 'factory_girl'

FactoryGirl.define do
  factory :file_set do
    factory :public_file_set do
      admin_policy_id AdminPolicy::PUBLIC_POLICY_ID
    end
  end
end
