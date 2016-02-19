require 'rails_helper'

describe CurationConcerns::AudioRecordingForm do
  describe '.model_attributes' do
    let(:params) { ActionController::Parameters.new(
                    license: "http://creativecommons.org/licenses/by-nc/4.0/") }
    subject { described_class.model_attributes(params) }
    it { is_expected.to eq("license" => ["http://creativecommons.org/licenses/by-nc/4.0/"]) }
  end
end

