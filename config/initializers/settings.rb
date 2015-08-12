class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env

  def proquest_directory
    File.join(download_root, 'proquest')
  end

  def marc_directory
    File.join(download_root, 'marc')
  end

  def pegasus_path
    pegasus_sru_endpoint
  end
end
