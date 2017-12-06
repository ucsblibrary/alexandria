# frozen_string_literal: true

FactoryBot.define do
  factory :topic do
    sequence(:label) { |n| "Label #{n}" }
  end
end
