//= require typeahead.bundle.js
// require handlebars-v1.3.0.js
//
var searchUris = {
  'lcnames':        '/qa/search/loc/names',
  'lcsh':           '/qa/search/loc/subjects',
  'lcrt':           '/qa/search/local/work_type',
  'tgm':            '/qa/search/loc/graphicMaterials',
  'aat':            '/qa/search/getty/aat',
  'local_subjects': '/qa/search/local/subjects',
  'local_names':    '/qa/search/local/names'
};


(function($){
  var defaultSearchForField = {
    'form_of_work':     searchUris['aat'],
    'location':         searchUris['lcnames'],
    'sub_location':     '/qa/search/local/sub_location',
    'lc_subject':       searchUris['lcsh'],
    'work_type':        searchUris['lcrt'],
    'rights_holder':    searchUris['local_names'],
    'contributor':      searchUris['lcnames'],
    'institution':      searchUris['lcnames'],
    'language':         '/qa/search/loc/iso639-2',
    'name_merge_target':    searchUris['local_names'],
    'subject_merge_target': searchUris['local_subjects']
  };

  function qaPathForField(input) {
    fieldName = input.data('attribute');
    return defaultSearchForField[fieldName];
  }

  function initBloodhound(path, selector_proxy) {
    function tt_hint_node() {
      return selector_proxy.parent().find('.tt-hint')
    }

    var results = new Bloodhound({
      datumTokenizer: function(d) { return Bloodhound.tokenizers.whitespace(d.title); },
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      limit: 15,
      remote: {
        url: path + '?q=%QUERY',
        filter: function(response) {
          tt_hint_node().removeClass('loading');
          return $.map(response, function(doc) {
            return doc;
          })
        },
        // If Bloodhound 0.11.0 is released we can remove this and use the callbacks:
        // typeahead:asyncrequest
        // typeahead:asynccancel
        // typeahead:asyncreceive
        replace: function(url, query){
            tt_hint_node().addClass('loading');
            return url.replace(this.wildcard, encodeURIComponent(query));
        }
      }
    });
    results.initialize();
    return results;
  }

  $.fn.alexandriaSearchTypeAhead = function( options ) {
    $.each(this, function(){
        options = $.extend({ searchPath: qaPathForField($(this)) }, options);
        addAutocompleteBehavior($(this), options);
    });

    function addAutocompleteBehavior( typeAheadInput, settings ) {
      var settings = $.extend({
        highlight: (typeAheadInput.data('autocomplete-highlight') || true),
        hint: true,
        autoselect: (typeAheadInput.data('autocomplete-autoselect') || true)
      }, settings);

      var results;
      if (settings.bloodhound) {
        results = settings.bloodhound();
      } else {
        results = initBloodhound(settings.searchPath, typeAheadInput);
      }

      typeAheadInput.typeahead(settings, {
        displayKey: 'label',
        source: results.ttAdapter()
      })

    }

    return this;
  }
})( jQuery );


function storeControlledVocabularyData(input, data) {
    uri = data['id'].replace("info:lc", "http://id.loc.gov");
    input.closest('.field-wrapper').find('[data-id]').val(uri);
}

function lockControlledVocabularyFields(input) {
   input.typeahead("destroy");
   input.attr("readonly", "readonly");
}

function addAnotherField(input) {
  input.closest('.form-group').find('.add').click();
}

/* Only call this once per field or the bindings' callbacks will be run more than once */
function addAutocompleteToEditor($field, options) {
    $field.alexandriaSearchTypeAhead(options).on(
        'typeahead:selected typeahead:autocompleted', function(e, data) {
            storeControlledVocabularyData($(this), data);
            lockControlledVocabularyFields($(this));
            addAnotherField($(this));
    }).on(
    'change', function(e) {
      // They didn't select anything. Clear the field.
      $(this).typeahead('val', '');
    });
}

Blacklight.onLoad(function() {
  // Only simple autocomplete here. Complex have it added by their editor.
  var fields = ['location', 'sub_location', 'language'];
  $.each(fields, function(i, value) {
      addAutocompleteToEditor($('input.image_'+value+':not([readonly])'));
  });
});

