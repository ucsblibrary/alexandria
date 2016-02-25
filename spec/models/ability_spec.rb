require 'spec_helper'
require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  subject { ability }

  before do
    AdminPolicy.ensure_admin_policy_exists

    # Load Image class or else it won't be returned in
    # ActiveFedora::Base.descendants, which is used to
    # check discovery permissions
    Image
  end

  let(:ability) { Ability.new(user) }
  let(:local_group) { create(:group) }

  let(:public_file_set) { create(:public_file_set) }
  let(:public_image) { create(:public_image) }
  let(:discovery_image) { create(:image, :discovery) }
  let(:restricted_image) { create(:image, :restricted) }
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

  context 'for a user who is not logged in' do
    let(:user) { User.new }

    it do
      is_expected.not_to be_able_to(:create, Image)
      is_expected.not_to be_able_to(:update, SolrDocument.new)

      is_expected.to be_able_to(:read, public_image)
      is_expected.not_to be_able_to(:update, public_image)
      is_expected.not_to be_able_to(:destroy, public_image)

      is_expected.to be_able_to(:discover, discovery_image)
      is_expected.not_to be_able_to(:discover, restricted_image)

      is_expected.to be_able_to(:read, public_file_set)

      is_expected.not_to be_able_to(:read, :local_authorities)
      is_expected.not_to be_able_to(:destroy, :local_authorities)

      is_expected.not_to be_able_to(:new_merge, local_group)
      is_expected.not_to be_able_to(:merge, local_group)

      is_expected.not_to be_able_to(:download_original, file_set_of_public_audio)
      is_expected.to be_able_to(:download_original, file_set_of_public_image)
    end
  end

  context 'for a logged-in UCSB user' do
    let(:user) { create(:ucsb_user) }

    it do
      is_expected.not_to be_able_to(:create, Image)
      is_expected.not_to be_able_to(:update, SolrDocument.new)

      is_expected.to be_able_to(:read, public_image)
      is_expected.not_to be_able_to(:update, public_image)
      is_expected.not_to be_able_to(:destroy, public_image)

      is_expected.to be_able_to(:discover, discovery_image)
      is_expected.not_to be_able_to(:discover, restricted_image)

      is_expected.not_to be_able_to(:read, :local_authorities)
      is_expected.not_to be_able_to(:destroy, :local_authorities)

      is_expected.not_to be_able_to(:new_merge, local_group)
      is_expected.not_to be_able_to(:merge, local_group)
    end
  end

  context 'for an metadata admin user' do
    let(:user) { create(:metadata_admin) }

    it do
      is_expected.to be_able_to(:create, Image)
      is_expected.to be_able_to(:update, SolrDocument.new)

      is_expected.to be_able_to(:read, public_image)
      is_expected.to be_able_to(:update, public_image)
      is_expected.to be_able_to(:destroy, public_image)

      is_expected.to be_able_to(:read, restricted_image)

      is_expected.to be_able_to(:read, :local_authorities)
      is_expected.to be_able_to(:destroy, :local_authorities)

      is_expected.to be_able_to(:new_merge, local_group)
      is_expected.to be_able_to(:merge, local_group)
      is_expected.to be_able_to(:merge, SolrDocument.new(local_group.to_solr))

      is_expected.not_to be_able_to(:discover, Hydra::AccessControls::Embargo)
      is_expected.not_to be_able_to(:edit_rights, ActiveFedora::Base)

      is_expected.to be_able_to(:download_original, file_set_of_public_audio)
    end
  end

  context 'for a rights admin user' do
    let(:user) { create(:rights_admin) }

    it do
      is_expected.not_to be_able_to(:create, Image)
      is_expected.not_to be_able_to(:update, SolrDocument.new)

      is_expected.to be_able_to(:read, public_image)
      is_expected.not_to be_able_to(:update, public_image)
      is_expected.not_to be_able_to(:destroy, public_image)

      is_expected.to be_able_to(:read, restricted_image)

      is_expected.not_to be_able_to(:read, :local_authorities)
      is_expected.not_to be_able_to(:destroy, :local_authorities)

      is_expected.not_to be_able_to(:new_merge, local_group)
      is_expected.not_to be_able_to(:merge, local_group)

      is_expected.to be_able_to(:discover, Hydra::AccessControls::Embargo)
      is_expected.to be_able_to(:update_rights, ActiveFedora::Base)
      is_expected.to be_able_to(:update_rights, String) # Hydra-collections calls this on the id
    end
  end
end
