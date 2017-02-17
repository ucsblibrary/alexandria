# coding: utf-8
# frozen_string_literal: true
module ApplicationHelper
  include CurationConcerns::CatalogHelper

  # Original version released under the MIT license by John Gruber:
  # https://gist.github.com/gruber/507356
  #
  # Modified to only match http/https URLs
  URL_REGEXP = %r{((?:https?:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))}

  def self.hostp
    Rails.application.config.host_name
  rescue NoMethodError
    raise "host_name is not configured"
  end

  # @param [String] string
  # @return [String]
  def linkify(string)
    string.gsub(URL_REGEXP, '<a href="\1">\1</a>')
  end

  # Used in {CatalogController} to render notes and restrictions as
  # separate paragraphs
  def not_simple_format(data)
    data[:value].map do |val|
      val.split('\n\n').map { |para| "<p>#{para}</p>" }
    end.flatten.join("").html_safe
  end

  def display_link(data)
    href = data.fetch(:value).first
    link_to(href, href)
  end

  def policy_title(document)
    AdminPolicy.find(document.admin_policy_id)
  end

  def random_thumbnail_from_collection(member_docs = [])
    thumb = member_docs.select { |doc| doc.key?("thumbnail_url_ssm") }.sample
    return nil unless thumb
    thumb["thumbnail_url_ssm"]
  end

  def show_license_icons(data)
    uri = data[:document]["license_tesim"].first

    icons = rights_icons(uri).map do |statement|
      image_tag(statement, class: "icon")
    end.join("")

    "<a href='#{uri}' title='Rights Statment'>#{icons} #{data[:value].first}</a>".html_safe
  end

  def rights_icons(uri)
    if category = uri.match(%r{.*rightsstatements\.org\/vocab\/([a-z]+)}i)
      [
        case category[1]
        when "InC"
          "rights-statements/InC.Icon-Only.dark.png"
        when "NoC"
          "rights-statements/NoC.Icon-Only.dark.png"
        else
          "rights-statements/Other.Icon-Only.dark.png"
        end,
      ].compact

    elsif categories = uri.match(%r{.*creativecommons\.org\/(licenses|publicdomain)\/([a-z-]+)}i)

      categories[2].split("-").map do |cat|
        "creative-commons/#{cat}.png"
      end
    else
      []
    end
  end
end
