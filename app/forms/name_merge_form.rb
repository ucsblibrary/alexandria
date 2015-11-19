class NameMergeForm
  include HydraEditor::Form

  attr_accessor :name_merge_target

  self.model_class = Agent
  self.required_fields = [:name_merge_target]
  self.terms = [:foaf_name]

  def title
    model.foaf_name
  end
end
