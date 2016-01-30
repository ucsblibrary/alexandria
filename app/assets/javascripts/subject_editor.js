//= require editor
var subject_manager_fields = "<input class=\"string {{class}} optional form-control image_{{name}} form-control multi-text-field\" name=\"image[{{name}}_attributes][{{index}}][hidden_label]\" value=\"\" id=\"image_{{name}}_attributes_{{index}}_hidden_label\" data-attribute=\"{{name}}\" type=\"text\">" +
  "<input name=\"image[{{name}}_attributes][{{index}}][id]\" value=\"\" id=\"image_{{name}}_attributes_{{index}}_id\" type=\"hidden\" data-id=\"remote\">" +
  "<input name=\"image[{{name}}_attributes][{{index}}][_destroy]\" id=\"image_{{name}}_attributes_{{index}}__destroy\" value=\"\" data-destroy=\"true\" type=\"hidden\"><span class=\"input-group-btn field-controls\"><button class=\"btn btn-success add\"><i class=\"icon-white glyphicon-plus\"></i><span>Add</span></button></span>";

var select_manager_select = "<select name=\"vocab\" id=\"vocab\" class=\"form-control\" data-behavior=\"change-vocabulary\" data-target=\"image_{{name}}_attributes_{{index}}_hidden_label\">{{optionsForSelect}}</select>"

var subject_manager_wrapper = "<li class=\"field-wrapper row\">"+
  "<div class=\"col-md-4\">"+select_manager_select+"</div>" +
  "<div class=\"col-md-8\"><div class=\"input-group input-group-append\">"+
  subject_manager_fields +"</div></div>" +
  "</li>";

var subject_manager_template = Handlebars.compile(subject_manager_wrapper);

function SubjectManager(element, options) {
    this.fieldName = options.fieldName;
    ControlledVocabFieldManager.call(this, element, options);
}

var label_for = {
    lcnames: "LC Names",
    lcsh: "LC Subject Headings",
    lcrt: "LC Resource Types",
    tgm: "Graphic Materials",
    aat: "Art & Architecture Thesaurus",
    local_names: 'Local Names',
    local_subjects: 'Local Subjects'
};

SubjectManager.prototype = Object.create(ControlledVocabFieldManager.prototype, {
    _addInitialClasses: {
        value: function () {
            this.element.addClass("managed");
            $(this.fieldWrapperClass, this.element).addClass("input-group input-append");
    }},

    editorTemplate: {
        value: function() {
            return $(subject_manager_template({ "name": this.fieldName, "index": this.maxIndex(), "class": "controlled_vocabulary_select", "optionsForSelect": this.buildOptions() }));

    }},

    buildOptions: {
        value: function() {
            buff = $.map(this.options.vocabularies, function (key) {
              return "<option value=\"" + key + "\">" + label_for[key] + "</option>";
            }).join('');
            return new Handlebars.SafeString(buff);
    }},

    displayEditor: {
        value: function() {
            var tmpl = this.editorTemplate();
            $(this.listClass, this.element).append(tmpl);
            this.addBehaviorsToInput(tmpl);
            _this = this;
            $('select', tmpl).on('change', function() {
                _this.switchControlledVocabularyFields($(this));
            });
    }},

    switchControlledVocabularyFields: {
        value: function(input) {
            var target = $('#'+input.data('target'));
            target.typeahead('val', '');
            target.typeahead("destroy");
            target.alexandriaSearchTypeAhead({ searchPath: searchUris[input.val()] });

    }},

    addToExisting: {
        value: function($editor) {
            this._changeControlsToRemove($editor);
            var elements = $('.input-group-append > *', $editor).detach();
            $editor.addClass('input-group input-append').removeClass('row')
            $editor.empty();
            $editor.append(elements);
    }},

    /* Overriding this to clear out the select options */
    addToList: {
        value: function(event) {
            event.preventDefault();
            var $activeField = $(event.target).parents(this.fieldWrapperClass)

            if (this.inputIsEmpty($activeField)) {
                this.displayEmptyWarning();
            } else {
                this.clearEmptyWarning();
                this.addToExisting($activeField);
                this.displayEditor();
            }
    }},

    /* Override so that all controls are just remove and wrapped in a col-md-8 */
    _appendControls: {
        value: function() {
            $(this.fieldWrapperClass, this.element).append(this.controls);
            $('.field-controls', this.element).append(this.remover);
            this.displayEditor();
        }
    },

    _changeControlsToRemove: {
        value: function($activeField) {
            var $removeControl = this.remover.clone();
            $activeFieldControls = $('.field-controls', $activeField);
            $('.add', $activeFieldControls).remove();
            $activeFieldControls.prepend($removeControl);
    }},
})

SubjectManager.prototype.constructor = SubjectManager;

$.fn.manage_subject_fields = function(option) {
    return this.each(function() {
        var $this = $(this);
        var data  = $this.data('manage_fields');
        var options = $.extend({}, HydraEditor.FieldManager.DEFAULTS, $this.data(), typeof option == 'object' && option);

        if (!data) $this.data('manage_fields', (data = new SubjectManager(this, options)));
    })
}

Blacklight.onLoad(function() {
  $('.form-group.image_lc_subject').manage_subject_fields({ fieldName: 'lc_subject', vocabularies: ['lcnames', 'lcsh', 'tgm', 'local_subjects', 'local_names'] });
  $('.form-group.image_form_of_work').manage_subject_fields({ fieldName: 'form_of_work', vocabularies: ['aat', 'tgm'] });
  $('.form-group.image_work_type').manage_subject_fields({ fieldName: 'work_type', vocabularies: ['lcrt'] });
  $('.form-group.image_rights_holder').manage_subject_fields({ fieldName: 'rights_holder', vocabularies: ['local_names', 'lcnames'] });
  $('.form-group.image_institution').manage_subject_fields({ fieldName: 'institution', vocabularies: ['lcnames', 'local_names'] });
});


