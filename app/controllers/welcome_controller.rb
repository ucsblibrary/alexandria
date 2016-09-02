# This is the controller that draws the home page
class WelcomeController < ApplicationController
  layout 'blacklight', except: :index

  def index
    @background = images.sample

    @object_url = Rails.application.secrets.ezid_default_shoulder.sub(%r{\/.{3}$}, '') +
                  "/#{@background['id']}"

    port = ':3000' unless Rails.env.production?
    size = 2000
    @background_url = "//#{Rails.application.config.host_name}#{port}"\
                      "/images/#{@background['image_path']}"\
                      "/#{@background['region']}/#{size},/0/default.jpg"
  end

  def about
  end

  def images
    @images ||= YAML.load(File.read(Rails.root.join('config', 'homepage.yml')))
  rescue Errno::ENOENT
    [{}]
  end
end
