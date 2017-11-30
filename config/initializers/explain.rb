# frozen_string_literal: true

if ENV["EXPLAIN_PARTIALS"]
  # https://gist.github.com/bmaddy/4567fad5aa55e5a600e1
  #
  # On Vagrant, Passenger is run under Apache, so EXPLAIN_PARTIALS must
  # be set in /etc/sysconfig/httpd; see
  # https://www.phusionpassenger.com/library/indepth/environment_variables.html
  module RenderWithExplanation
    def render(*args)
      rendered = super(*args).to_s
      # Note: We haven't figured out how to get a path when @template is nil.
      start_explanation = "\n<!-- START PARTIAL #{@template.inspect} -->\n"
      end_explanation = "\n<!-- END PARTIAL #{@template.inspect} -->\n"
      (start_explanation + rendered + end_explanation).html_safe
    end
  end

  class ActionView::PartialRenderer
    prepend RenderWithExplanation
  end
end
