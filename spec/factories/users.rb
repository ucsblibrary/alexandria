require 'factory_girl'
FactoryGirl::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end

FactoryGirl.define do
  factory :user do
    sequence :username do |n|
      "person#{User.count}_#{n}"
    end
    group_list [AdminPolicy::PUBLIC_GROUP]

    # Prevent ldap from being called
    groups_list_expires_at { 1.day.from_now }

    factory :metadata_admin, aliases: [:admin] do
      group_list [AdminPolicy::META_ADMIN_GROUP]
    end

    factory :rights_admin do
      group_list [AdminPolicy::RIGHTS_ADMIN_GROUP]
    end

    factory :ucsb_user do
      group_list [AdminPolicy::UCSB_GROUP]
    end
  end
end
