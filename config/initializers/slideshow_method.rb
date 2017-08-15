# frozen_string_literal: true

module Blacklight::GalleryHelper
  WITH_LARGE_IMAGES = %w[
    Image
    ComponentMap
    IndexMap
    ScannedMap
  ].freeze

  def choose_image(document, options)
    if WITH_LARGE_IMAGES.include? document["has_model_ssim"].first
      image_tag(document["image_url_ssm"].first, options)
    else
      render_thumbnail_tag(document, options)
    end
  end
end
