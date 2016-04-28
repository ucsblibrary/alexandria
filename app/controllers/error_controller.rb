class ErrorController < ApplicationController
  # see http://blog.grepruby.com/2015/04/custom-error-pages-with-rails-4.html
  def not_found
    respond_to do |format|
      format.html { render template: 'errors/not_found', status: 404 }
      format.all { render nothing: true, status: 404 }
    end
  end

  def server_error
    respond_to do |format|
      format.html { render template: 'errors/server_error', status: 500 }
      format.all { render nothing: true, status: 500 }
    end
  end
end
