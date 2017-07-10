# frozen_string_literal: true

class Settings < Settingslogic
  source Rails.root.join("config", "application.yml")
  namespace Rails.env

  def proquest_directory
    File.join(download_root, "proquest")
  end

  def marc_directory
    File.join(download_root, "marc")
  end
end
