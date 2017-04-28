# frozen_string_literal: true

class ComponentMapForm < ObjectForm
  self.model_class = ComponentMap

  self.terms = ObjectForm.terms + [:scale]
end
