# coding: utf-8
module ApplicationHelper
  include CurationConcerns::CatalogHelper

  # Original version released under the MIT license by John Gruber:
  # https://gist.github.com/gruber/507356
  #
  # Modified to only match http/https URLs
  URL_REGEXP = %r{((?:https?:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))}

  # @param [String] string
  # @return [String]
  def linkify(string)
    string.gsub(URL_REGEXP, '<a href="\1">\1</a>')
  end

  def link_to_collection(stuff)
    collection_id = Array(stuff.fetch(:document)[ObjectIndexer::COLLECTION]).first
    if collection_id
      link_to stuff.fetch(:value).first, collection_path(collection_id)
    else
      stuff.fetch(:value).first
    end
  end

  # Used in {CatalogController} to render notes and restrictions as
  # separate paragraphs
  def not_simple_format(data)
    data[:value].map do |val|
      val.split('\n\n').map { |para| "<p>#{para}</p>" }
    end.flatten.join('').html_safe
  end

  def display_link(data)
    href = data.fetch(:value).first
    link_to(href, href)
  end

  def policy_title(document)
    AdminPolicy.find(document.admin_policy_id)
  end

  def random_thumbnail_from_collection(member_docs = [])
    member_docs.select {|doc| doc.has_key?("thumbnail_url_ssm") }.sample["thumbnail_url_ssm"]
  end

end
