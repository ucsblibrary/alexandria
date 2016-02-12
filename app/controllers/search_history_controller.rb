# This is SeachHistoryController from Blacklight, updated
# to support Blacklight Range Limit
class SearchHistoryController < ApplicationController
  include Blacklight::SearchHistory

  helper BlacklightRangeLimit::ViewHelperOverride
  helper RangeLimitHelper
end
