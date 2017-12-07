# frozen_string_literal: true

FactoryBot.define do
  factory :file_set do
    factory :public_file_set do
      admin_policy_id AdminPolicy::PUBLIC_POLICY_ID
    end
  end
end
