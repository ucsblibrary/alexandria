# frozen_string_literal: true

require "spec_helper"
require "rails_helper"
require "cancan/matchers"

describe Ability do
  subject { ability }

  before do
    AdminPolicy.ensure_admin_policy_exists
    allow(embargoed_fs).to receive(:parent).and_return(embargoed_etd)

    # Load Image class or else it won't be returned in
    # ActiveFedora::Base.descendants, which is used to
    # check discovery permissions
    Image
  end

  let(:ability) { described_class.new(user) }
  let(:discovery_image) { create(:image, :discovery) }
  let(:local_group) { create(:group) }
  let(:public_file_set) { create(:public_file_set) }
  let(:public_image) { create(:public_image) }
  let(:restricted_image) { create(:image, :restricted) }

  let(:embargoed_etd) do
    ETD.create!(
      title: ["weh"],
      admin_policy_id: AdminPolicy::DISCOVERY_POLICY_ID
    )
  end

  let(:embargoed_fs) do
    FileSet.create!(
      title: ["woh"],
      admin_policy_id: AdminPolicy::DISCOVERY_POLICY_ID
    )
  end

  let(:file_set_of_public_audio) do
    create(:public_file_set).tap do |fs|
      create(:public_audio, ordered_members: [fs])
    end
  end

  let(:file_set_of_public_image) do
    create(:public_file_set).tap do |fs|
      create(:public_image, ordered_members: [fs])
    end
  end

  context "for a user who is not logged in" do
    let(:user) { User.new }

    it do
      expect(subject).not_to be_able_to(:create, Image)
      expect(subject).not_to be_able_to(:update, SolrDocument.new)

      expect(subject).to be_able_to(:read, public_image)
      expect(subject).not_to be_able_to(:update, public_image)
      expect(subject).not_to be_able_to(:destroy, public_image)

      expect(subject).to be_able_to(:discover, discovery_image)
      expect(subject).not_to be_able_to(:discover, restricted_image)

      expect(subject).to be_able_to(:read, public_file_set)

      expect(subject).not_to be_able_to(:read, :local_authorities)
      expect(subject).not_to be_able_to(:destroy, :local_authorities)

      expect(subject).not_to be_able_to(:new_merge, local_group)
      expect(subject).not_to be_able_to(:merge, local_group)

      expect(subject).not_to(
        be_able_to(:download_original, file_set_of_public_audio)
      )
      expect(subject).to be_able_to(:download_original, file_set_of_public_image)
    end
  end

  context "for a logged-in UCSB user" do
    let(:user) { user_with_groups [AdminPolicy::UCSB_GROUP] }

    it do
      expect(subject).not_to be_able_to(:create, Image)
      expect(subject).not_to be_able_to(:update, SolrDocument.new)

      expect(subject).to be_able_to(:read, public_image)
      expect(subject).not_to be_able_to(:update, public_image)
      expect(subject).not_to be_able_to(:destroy, public_image)

      expect(subject).to be_able_to(:discover, discovery_image)
      expect(subject).not_to be_able_to(:discover, restricted_image)

      expect(subject).not_to be_able_to(:read, :local_authorities)
      expect(subject).not_to be_able_to(:destroy, :local_authorities)

      expect(subject).not_to be_able_to(:new_merge, local_group)
      expect(subject).not_to be_able_to(:merge, local_group)
    end
  end

  context "for an metadata admin user" do
    let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }

    it do
      expect(subject).to be_able_to(:create, Image)
      expect(subject).to be_able_to(:update, SolrDocument.new)

      expect(subject).to be_able_to(:read, public_image)
      expect(subject).to be_able_to(:update, public_image)
      expect(subject).to be_able_to(:destroy, public_image)

      expect(subject).to be_able_to(:read, restricted_image)

      expect(subject).to be_able_to(:read, :local_authorities)
      expect(subject).to be_able_to(:destroy, :local_authorities)

      expect(subject).to be_able_to(:new_merge, local_group)
      expect(subject).to be_able_to(:merge, local_group)
      expect(subject).to be_able_to(:merge, SolrDocument.new(local_group.to_solr))

      expect(subject).to be_able_to(:discover, embargoed_etd)
      expect(subject).to be_able_to(:read, embargoed_etd)
      expect(subject).to be_able_to(:edit, embargoed_etd)
      expect(subject).to be_able_to(:discover, embargoed_fs)
      expect(subject).not_to be_able_to(:read, embargoed_fs)
      expect(subject).not_to be_able_to(:edit, embargoed_fs)

      expect(subject).not_to be_able_to(:discover, Hydra::AccessControls::Embargo)
      expect(subject).not_to be_able_to(:edit_rights, ActiveFedora::Base)

      expect(subject).to be_able_to(:download_original, file_set_of_public_audio)
    end
  end

  context "for a rights admin user" do
    let(:user) { user_with_groups [AdminPolicy::RIGHTS_ADMIN] }

    it do
      expect(subject).not_to be_able_to(:create, Image)
      expect(subject).not_to be_able_to(:update, SolrDocument.new)

      expect(subject).to be_able_to(:read, public_image)
      expect(subject).not_to be_able_to(:update, public_image)
      expect(subject).not_to be_able_to(:destroy, public_image)

      expect(subject).to be_able_to(:read, restricted_image)

      expect(subject).not_to be_able_to(:read, :local_authorities)
      expect(subject).not_to be_able_to(:destroy, :local_authorities)

      expect(subject).not_to be_able_to(:new_merge, local_group)
      expect(subject).not_to be_able_to(:merge, local_group)

      expect(subject).to be_able_to(:discover, embargoed_etd)
      expect(subject).to be_able_to(:read, embargoed_etd)
      expect(subject).not_to be_able_to(:edit, embargoed_etd)
      expect(subject).to be_able_to(:discover, embargoed_fs)
      expect(subject).to be_able_to(:read, embargoed_fs)
      expect(subject).not_to be_able_to(:edit, embargoed_fs)

      expect(subject).to be_able_to(:discover, Hydra::AccessControls::Embargo)
      expect(subject).to be_able_to(:update_rights, ActiveFedora::Base)

      # Hydra-collections calls this on the id
      expect(subject).to be_able_to(:update_rights, String)
    end
  end
end
