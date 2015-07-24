require 'factory_girl'

FactoryGirl.define do
  factory :user do
    sequence :username do |n|
      "person#{User.count}_#{n}"
    end
    password 'password'

    factory :admin do
      roles { [Role.where(name: 'admin').first_or_create] }
    end
  end
end
