require 'factory_girl'

FactoryGirl.define do
  factory :audio, class: AudioRecording do
    title ['Test Recording']

    factory :public_audio do
      admin_policy_id AdminPolicy::PUBLIC_POLICY_ID
    end
  end
end

