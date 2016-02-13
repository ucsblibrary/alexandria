require 'factory_girl'

FactoryGirl.define do
  factory :etd, class: ETD do
    work_type [RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/txt')]
    title ['Test Thesis']

    factory :public_etd do
      admin_policy_id AdminPolicy::PUBLIC_POLICY_ID
    end
  end
end
