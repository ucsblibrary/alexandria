class TopicForm
  include HydraEditor::Form

  self.model_class = Topic
  self.required_fields = []
  self.terms = [:label]

  def title
    model.label
  end
end
