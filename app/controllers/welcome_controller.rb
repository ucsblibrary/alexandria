# This is the controller that draws the home page
class WelcomeController < ApplicationController
  layout 'blacklight', except: :index

  def index
  end

  def about
  end
end
