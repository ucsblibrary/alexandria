# frozen_string_literal: true

class MapSetForm < ObjectForm
  self.model_class = MapSet

  self.terms = ObjectForm.terms + [:scale]
end
