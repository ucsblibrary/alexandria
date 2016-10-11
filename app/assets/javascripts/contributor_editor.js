//= require subject_editor
var contributor_manager_fields = "<input class=\"string {{class}} optional form-control image_{{name}} form-control multi-text-field\" name=\"image[{{name}}_attributes][{{index}}][hidden_label]\" value=\"\" id=\"image_{{name}}_attributes_{{index}}_hidden_label\" data-attribute=\"{{name}}\" type=\"text\">" +
  "<input name=\"image[{{name}}_attributes][{{index}}][id]\" value=\"\" id=\"image_{{name}}_attributes_{{index}}_id\" type=\"hidden\" data-id=\"remote\">" +
  "<input name=\"image[{{name}}_attributes][{{index}}][_destroy]\" id=\"image_{{name}}_attributes_{{index}}__destroy\" value=\"\" data-destroy=\"true\" type=\"hidden\"><span class=\"input-group-btn field-controls\"><button class=\"btn btn-success add\"><i class=\"icon-white glyphicon-plus\"></i><span>Add</span></button></span>";

var role_manager_select = "<select name=\"role\" id=\"{{name}}_role_{{index}}\" class=\"form-control\">{{relatorOptions}}</select>";

var hidden_role_input = "<input name=\"image[{{name}}_attributes][{{index}}][predicate]\" value=\"{{value}}\" id=\"image_{{name}}_attributes_{{index}}_predicate\" type=\"hidden\"><span class=\"predicate\">{{roleLabel}}</span>"
var hidden_role_template = Handlebars.compile(hidden_role_input);

var contributor_manager_wrapper = "<li class=\"field-wrapper row new\">"+
  "<div class=\"role\">"+role_manager_select+"</div>" +
  "<div class=\"vocabulary\">"+select_manager_select+"</div>" +
  "<div class=\"text\"><div class=\"input-group input-group-append\">"+
  contributor_manager_fields +"</div></div>" +
  "</li>";

var contributor_manager_template = Handlebars.compile(contributor_manager_wrapper);

function ContributorManager(element, options) {
    this.fieldName = options.fieldName;
    var relatorOptTemplate = Handlebars.compile("<option value=\"{{key}}\">{{label}}</option>");
    this.relatorOptions = new Handlebars.SafeString($.map(options.relators, function(label, key) {
      return relatorOptTemplate({key: key, label: label});
    }).join(''));
    ControlledVocabFieldManager.call(this, element, options);
}

ContributorManager.prototype = Object.create(SubjectManager.prototype, {
    _addInitialClasses: {
        value: function () {
            this.element.addClass("managed");
    }},

    editorTemplate: {
        value: function() {
            return $(contributor_manager_template({ "name": this.fieldName, "index": this.maxIndex(), "class": "controlled_vocabulary_select", "optionsForSelect": this.buildOptions(), "relatorOptions": this.relatorOptions }));
    }},

    /* Override so that all controls are injected into the .text node */
    _appendControls: {
        value: function() {
            $(this.fieldWrapperClass + ' > .text > .input-group', this.element).append(this.controls);
            $('.field-controls', this.element).append(this.remover);
            this.displayEditor();
        }
    },

    addToExisting: {
        value: function($editor) {
            this._changeControlsToRemove($editor);
            var selector = $('[name="role"]', $editor);
            var label = $('option:selected', selector).text();
            var newContent = hidden_role_template(
              { "name": this.fieldName, "value": selector.val(),
                 "index": this.maxIndex() - 1, "roleLabel": label });

            $editor.removeClass('new').addClass('existing');
            // Get rid of the middle column
            $('.vocabulary', $editor).remove();
            $('.role', $editor).html(newContent);
    }},
})

ContributorManager.prototype.constructor = ContributorManager;

$.fn.manage_contributor_fields = function(option) {
    return this.each(function() {
        var $this = $(this);
        var data  = $this.data('manage_fields');
        var options = $.extend({}, AlexandriaEditor.FieldManager.DEFAULTS, $this.data(), typeof option == 'object' && option);

        if (!data) $this.data('manage_fields', (data = new ContributorManager(this, options)));
    })
}

Blacklight.onLoad(function() {
  // This script depends on setting a global variable `relators` that holds the values for
  // the predicate options
  if (typeof(relators) !== 'undefined') {
    $('.form-group.image_contributor').manage_contributor_fields({ fieldName: 'contributor', vocabularies: ['lcnames', 'local_names'], relators: relators });
  }
});



