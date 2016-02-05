require 'factory_girl'

FactoryGirl.define do
  factory :topic do
    sequence(:label) { |n| "Label #{n}" }
  end
end
