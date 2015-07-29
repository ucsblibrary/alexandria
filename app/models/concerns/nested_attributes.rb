# accepts_nested_attributes_for can not be called until all the properties are declared
# because it calls resource_class, which finalizes the propery declarations
# See https://github.com/projecthydra/active_fedora/issues/847
module NestedAttributes
  extend ActiveSupport::Concern

  included do
    id_blank = proc { |attributes| attributes[:id].blank? }

    Metadata::RELATIONS.keys.each do |relation|
      accepts_nested_attributes_for relation, reject_if: id_blank, allow_destroy: true
    end
    accepts_nested_attributes_for :location, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :license, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :lc_subject, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :form_of_work, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :copyright_status, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :language, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :rights_holder, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :institution, reject_if: id_blank, allow_destroy: true

    accepts_nested_attributes_for :notes, reject_if: :all_blank, allow_destroy: true

    # dates
    accepts_nested_attributes_for :created, reject_if: :time_span_blank, allow_destroy: true
    accepts_nested_attributes_for :date_other, reject_if: :time_span_blank, allow_destroy: true
    accepts_nested_attributes_for :date_copyrighted, reject_if: :time_span_blank, allow_destroy: true
    accepts_nested_attributes_for :date_valid, reject_if: :time_span_blank, allow_destroy: true
  end
end
