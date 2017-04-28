# frozen_string_literal: true

class ScannedMapForm < ObjectForm
  self.model_class = ScannedMap

  self.terms = ObjectForm.terms + [:scale]
end
