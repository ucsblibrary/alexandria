# frozen_string_literal: true

require "traject/extract_contributors"

module ExtractCylinderContributors
  include ExtractContributors

  def roles_for(field)
    roles = %w[4 e].map do |code|
      trim_subfield(field, code)
    end.compact.flatten

    return [:performer] if roles.blank?

    roles.map { |r| ROLE_MAP.fetch(r.strip.downcase) }
  end
end
