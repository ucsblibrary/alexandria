# frozen_string_literal: true
module EzidHelper
  # For specs where you aren't testing the behavior of
  # minted ARKs, you can just stub out Ezid.
  #
  # @param ids [String, Array] The ID that you want the
  #   stubbed-out identifier object to have.
  #   If your spec calls Ezid::Identifier.mint more than once
  #   and you want to return a different identifier each time,
  #   you can pass in an array of IDs instead of a single ID.
  #
  def stub_out_ezid(ids = "123")
    identifiers = Array(ids).map do |id|
      double(id: id, "[]=": nil, save: nil)
    end

    allow(Ezid::Identifier).to receive(:mint).and_return(*identifiers)
  end
end
