require 'factory_girl'

FactoryGirl.define do
  factory :collection do
    title ['test collection']
    id { SecureRandom.uuid }
    factory :public_collection do
      before(:create) { AdminPolicy.ensure_admin_policy_exists }
      admin_policy_id AdminPolicy::PUBLIC_POLICY_ID
    end
  end
end
