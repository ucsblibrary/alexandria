# This is the controller that draws the home page
class WelcomeController < ApplicationController
  layout 'blacklight', except: :index

  def index
    @background = images.sample

    port = ':3000' unless Rails.env.production?
    size = 2000
    @background['url'] = "http://#{Rails.application.config.host_name}#{port}"\
                         "/images/#{@background['image_path']}"\
                         "/#{@background['region']}/#{size},/0/default.jpg"
  end

  def about
  end

  def images
    @images ||= YAML.load(File.read(Rails.root.join('config', 'homepage.yml')))
  end
end
