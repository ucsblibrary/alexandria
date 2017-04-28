# frozen_string_literal: true

class IndexMapForm < ObjectForm
  self.model_class = IndexMap

  self.terms = ObjectForm.terms + [:scale]
end
