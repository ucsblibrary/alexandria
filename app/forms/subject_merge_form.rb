class SubjectMergeForm
  include HydraEditor::Form

  attr_accessor :subject_merge_target

  self.model_class = Topic
  self.required_fields = [:subject_merge_target]
  self.terms = [:label]

  def title
    Array(model.label).join(', ')
  end
end
