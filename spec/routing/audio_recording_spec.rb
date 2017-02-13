# frozen_string_literal: true
require "rails_helper"

describe "routes to AudioRecording" do
  let(:recording) do
    AudioRecording.create!(title: ["Any rags"],
                           description: ["Baritone solo with orchestra accompaniment."],
                           admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID)
  end

  it "uses the correct controller" do
    # Ensure that AudioRoutingConcern is satisfied and the page is
    # rendered by the right controller
    expect(get: curation_concerns_audio_recording_path(recording)).to route_to(controller: "curation_concerns/audio_recordings", action: "show", id: recording.id)
  end
end
