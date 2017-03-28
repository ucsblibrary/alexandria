# frozen_string_literal: true

require "rails_helper"

describe EmbargoQueryService do
  let(:future_date) { 2.days.from_now }
  let(:past_date) { 2.days.ago }

  let!(:work_with_expired_embargo1) do
    build(:etd, embargo_release_date: past_date.to_s).tap do |work|
      work.save(validate: false)
    end
  end

  let!(:work_with_expired_embargo2) do
    build(:etd, embargo_release_date: past_date.to_s).tap do |work|
      work.save(validate: false)
    end
  end

  let!(:work_with_embargo_in_effect) { create(:etd, embargo_release_date: future_date.to_s) }
  let!(:work_without_embargo) { create(:etd) }

  let!(:file_with_embargo_in_effect) { create(:file_set, embargo_release_date: future_date.to_s) }
  let!(:file_with_expired_embargo) { create(:file_set, embargo_release_date: past_date.to_s) }

  describe "#assets_with_expired_embargoes" do
    it "returns an array of assets with expired embargoes" do
      returned_pids = subject.assets_with_expired_embargoes.map(&:id)
      expect(returned_pids).to include work_with_expired_embargo1.id, work_with_expired_embargo2.id
      expect(returned_pids).to_not include work_with_embargo_in_effect.id, work_without_embargo.id
    end
  end

  describe "#works_with_expired_embargoes" do
    let(:returned_pids) { subject.works_with_expired_embargoes.map(&:id) }

    it "returns an array of works with expired embargoes" do
      expect(returned_pids).to include(
        work_with_expired_embargo1.id,
        work_with_expired_embargo2.id
      )
      expect(returned_pids).to_not include(
        work_with_embargo_in_effect.id,
        work_without_embargo.id,
        file_with_expired_embargo.id,
        file_with_embargo_in_effect.id
      )
    end
  end

  describe "#assets_under_embargo" do
    it "returns all assets with embargo release date set" do
      returned_pids = subject.assets_under_embargo.map(&:id)
      expect(returned_pids).to include(
        work_with_expired_embargo1.id,
        work_with_expired_embargo2.id,
        work_with_embargo_in_effect.id,
        file_with_embargo_in_effect.id
      )
      expect(returned_pids).to_not include work_without_embargo.id
    end
  end

  describe "#works_under_embargo" do
    let(:returned_pids) { subject.works_under_embargo.map(&:id) }

    it "returns all works with embargo release date set" do
      expect(returned_pids).to include(
        work_with_expired_embargo1.id,
        work_with_expired_embargo2.id,
        work_with_embargo_in_effect.id
      )
      expect(returned_pids).to_not include(
        work_without_embargo.id,
        file_with_embargo_in_effect.id
      )
    end
  end
end
