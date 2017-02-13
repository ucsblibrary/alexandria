# frozen_string_literal: true
module ContactUsHelper
  def contact_us_categories
    [
      "General Inquiry or Request",
      "Copyright Information",
      "Feedback",
      "Report Problem",
    ]
  end

  def contact_us_fields_class
    "col-xs-12 col-sm-6"
  end
end
