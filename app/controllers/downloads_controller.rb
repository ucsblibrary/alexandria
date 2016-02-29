# This extends the DownloadController from Hydra-Core in order to unescape
# slashes in the ids. It also ensures that when you pass the id for a FileSet
# you are going to be served the orignal pcdm:File (not a derivative)
class DownloadsController < ApplicationController
  include CurationConcerns::DownloadBehavior

  protected

    # NOTE the ID may be uri escaped:
    #   e.g.: ca%2Fc0%2Ff3%2Ff4%2Fcac0f3f4-ea8f-414d-a7a5-3253ef003b1a
    def asset
      @asset ||= ActiveFedora::Base.find(URI.unescape(params[asset_param_key]))
    end

    # set the disposition to attachment for downloading
    def derivative_download_options
      return { type: mime_type_for(file), filename: file_name, disposition: 'attachment' } if params[:dl].present?
      super
    end

    def authorize_download!
      return authorize!(:download_original, asset) if original_file?
      super
    end

    def file_name
      # This path is called if they want to download an MP3
      return filename_for_derivative if file.is_a? String
      super
    end

    def filename_for_derivative
      File.basename(asset.restored.original_name, '.*') + ".#{params[:file]}"
    end

    def original_file?
      params[:file].nil?
    end
end
