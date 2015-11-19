module OptionsHelper
  def digital_origin_options
    local_string_options('digital_origin')
  end

  def description_standard_options
    local_string_options('description_standard')
  end

  def sub_location_options
    local_string_options('sub_location')
  end

  # this is a local cache of LOC copyrightStatus
  def copyright_status_options
    local_uri_options('copyright_status')
  end

  def license_options
    local_uri_options('license')
  end

  # @return Hash of relators in JSON with creator and contributor at the top.
  def relators_json
    rels = { creator: 'Creator', contributor: 'Contributor' }
    keys = Metadata::MARCREL.keys - [:creator, :contributor]
    keys.each_with_object(rels) { |key, h| h[key] = key.to_s.humanize }.to_json.html_safe
  end

  private

    def local_uri_options(field)
      Qa::Authorities::Local.subauthority_for(field).all.each_with_object({}) do |t, h|
        h[t['label'.freeze]] = t['id'.freeze]
      end
    end

    def local_string_options(field)
      Qa::Authorities::Local.subauthority_for(field).all.map { |t| t['label'.freeze] }
    end
end
