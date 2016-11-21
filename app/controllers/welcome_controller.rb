# This is the controller that draws the home page
class WelcomeController < ApplicationController
  layout 'blacklight', except: :index

  def index
    @background = images.sample
  end

  def about
  end

  def help
  end

  def images
    @images ||= YAML.load(File.read(Rails.root.join('config', 'homepage.yml')))
  rescue Errno::ENOENT
    [{}]
  end
end
