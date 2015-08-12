function EmbargoForm(element) {
   this.element = $(element);
   this.embargoField = $('input#etd_embargo', this.element);
   this.embargoNotice = $('#embargo-notice', this.element);
   this.currentAccessFieldGroup = $('div.etd_admin_policy_id', this.element);
   this.currentAccessField = $('select#etd_admin_policy_id', this.currentAccessFieldGroup);
   this.embargoReleaseDateFieldGroup = $('div.etd_embargo_release_date', this.element);
   this.visibilityAfterFieldGroup = $('div.etd_visibility_after_embargo_id', this.element);
   this.visibilityAfterField = $('select#etd_visibility_after_embargo_id', this.visibilityAfterFieldGroup);
   this.addEmbargoButton = $('#add_embargo_button', this.element);
   this.removeEmbargoButton = $('#remove_embargo_button', this.element);
   this.endEarlyButton = $('#end_early_button', this.element);
   this.init();
}

EmbargoForm.prototype = {
    init: function () {
        if (this.isEmbargoEnabled())
          this.activateEditEmbargoState();
        else
          this.activateEditPolicyState();

        var that = this;
        this.removeEmbargoButton.on('click', function(e) {
            $(e.target).closest('form').find('input[name=_method]').val('delete');
            //that.removeEmbargo();
        });

        this.addEmbargoButton.on('click', function(e) {
            e.preventDefault();
            that.createEmbargo();
        });

        this.endEarlyButton.on('click', function(e) {
            e.preventDefault();
            that.endEarly();
        });
    },

    endEarly: function() {
        this.currentAccessField.val(this.visibilityAfterField.val());
        this.removeEmbargo();
    },

    createEmbargo: function() {
        this.embargoNotice.show();
        this.embargoField.val("true");
        this.editOrCreateState();
    },

    activateEditEmbargoState: function () {
        this.currentAccessField.prop('disabled', true);
        this.editOrCreateState();
    },

    editOrCreateState: function() {
        this.addEmbargoButton.hide();
        this.embargoReleaseDateFieldGroup.show();
        this.visibilityAfterFieldGroup.show();
        this.removeEmbargoButton.show();
        this.endEarlyButton.show();
        this.removeEmbargoButton.show();
    },

    removeEmbargo: function() {
        this.embargoNotice.hide();
        this.embargoField.val("false");
        this.currentAccessField.prop('disabled', false);
        this.activateEditPolicyState();
    },

    activateEditPolicyState: function () {
        this.addEmbargoButton.show();
        this.embargoReleaseDateFieldGroup.hide();
        this.visibilityAfterFieldGroup.hide();
        this.removeEmbargoButton.hide();
        this.endEarlyButton.hide();
        this.removeEmbargoButton.hide();
    },

    isEmbargoEnabled: function () {
        return this.embargoField.val() == "true";
    }
}

$.fn.embargo_form = function() {
    return this.each(function() {
        var $this = $(this);
        var data  = $this.data('embargo_form');
        if (!data) $this.data('embargo_form', (data = new EmbargoForm(this)));
    })
}

Blacklight.onLoad(function() {
  $('#embargo-form').embargo_form();
})

