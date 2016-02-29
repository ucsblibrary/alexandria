module CurationConcerns
  class AudioRecordingForm < CurationConcerns::Forms::WorkForm
    self.model_class = ::AudioRecording
    delegate :license, to: :model

    self.terms -= [:rights]
    self.terms += [:license]

    # Overriden to cast 'license' to an array
    def self.sanitize_params(form_params)
      form_params['license'] = Array(form_params['license']) if form_params.key?('license')
      super(form_params)
    end
  end
end
