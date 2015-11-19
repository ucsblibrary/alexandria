class AgentForm
  include HydraEditor::Form

  self.model_class = Agent

  self.required_fields = []

  self.terms = [:foaf_name]

  def title
    model.foaf_name
  end
end
