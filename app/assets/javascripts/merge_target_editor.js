//= require subject_editor

var merge_target_field = "<input class=\"string {{class}} required {{name}} form-control multi-text-field\" name=\"[{{name}}_attributes][{{index}}][hidden_label]\" value=\"\" id=\"{{name}}_attributes_{{index}}_hidden_label\" data-attribute=\"{{name}}\" type=\"text\">" +
  "<input name=\"[{{name}}_attributes][{{index}}][id]\" value=\"\" id=\"{{name}}_attributes_{{index}}_id\" type=\"hidden\" data-id=\"remote\">";

var merge_target_template = Handlebars.compile(merge_target_field);

var merge_target_wrapper = "<li class=\"field-wrapper row new\">" +
  "<div class=\"text\"><div class=\"input-group-append\">" +
  merge_target_field + "</div></div>" + "</li>";

var merge_target_manager_template = Handlebars.compile(merge_target_wrapper);


function MergeTargetManager(element, options) {
    this.fieldName = options.fieldName;
    ControlledVocabFieldManager.call(this, element, options);
}

MergeTargetManager.prototype = Object.create(SubjectManager.prototype, {
    editorTemplate: {
        value: function() {
            return $(merge_target_manager_template({ "name": this.fieldName, "index": this.maxIndex(), "class": "controlled_vocabulary_select" }));
    }},
})

MergeTargetManager.prototype.constructor = MergeTargetManager;

$.fn.manage_merge_target_field = function(option) {
    return this.each(function() {
        var $this = $(this);
        var data  = $this.data('manage_fields');
        var options = $.extend({}, AlexandriaEditor.FieldManager.DEFAULTS, $this.data(), typeof option == 'object' && option);

        if (!data) $this.data('manage_fields', (data = new MergeTargetManager(this, options)));
    })
}


Blacklight.onLoad(function() {
    $('.form-group.topic_subject_merge_target').manage_merge_target_field({ fieldName: 'subject_merge_target', vocabularies: ['local_subjects'] });

  var selectorsForNameMerge = [$('.form-group.agent_name_merge_target'), 
      $('.form-group.person_name_merge_target'),
      $('.form-group.group_name_merge_target'),
      $('.form-group.organization_name_merge_target')];

  selectorsForNameMerge.map(function(selector) {
      selector.manage_merge_target_field({ fieldName: 'name_merge_target', vocabularies: ['local_names'] });
    });
});

