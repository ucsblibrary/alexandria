# This extends the DownloadController from Hydra-Core in order to unescape
# slashes in the ids. It also ensures that when you pass the id for a FileSet
# you are going to be served the orignal pcdm:File (not a derivative)
class DownloadsController < ApplicationController
  include CurationConcerns::DownloadBehavior

  # NOTE the ID may be uri escaped:
  #   e.g.: ca%2Fc0%2Ff3%2Ff4%2Fcac0f3f4-ea8f-414d-a7a5-3253ef003b1a
  def asset
    @asset ||= ActiveFedora::Base.find(URI.unescape(params[asset_param_key]))
  end
end
