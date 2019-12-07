# frozen_string_literal: true

FactoryBot.define do
  factory :agent do
    sequence(:foaf_name) { |n| "Agent #{n}" }
  end

  factory :person, parent: :agent, class: "Person"

  factory :group, parent: :agent, class: "Group"

  factory :organization, parent: :agent, class: "Organization", aliases: [:org]
end
