require 'spec_helper'
require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  subject { ability }
  let(:ability) { Ability.new(user) }
  let(:image) { Image.create! }
  let(:local_group) { create(:group) }

  context 'for a normal user' do
    let(:user) { User.new }

    it {
      is_expected.to be_able_to(:read, image)

      is_expected.not_to be_able_to(:create, Image)
      is_expected.not_to be_able_to(:update, image)
      is_expected.not_to be_able_to(:destroy, image)

      is_expected.not_to be_able_to(:read, :local_authorities)
      is_expected.not_to be_able_to(:destroy, :local_authorities)

      is_expected.not_to be_able_to(:new_merge, local_group)
      is_expected.not_to be_able_to(:merge, local_group)
    }
  end

  context 'for an metadata admin user' do
    let(:user) { create(:metadata_admin) }

    it {
      is_expected.to be_able_to(:read, image)
      is_expected.to be_able_to(:create, Image)
      is_expected.to be_able_to(:update, image)
      is_expected.to be_able_to(:update, SolrDocument.new)

      is_expected.not_to be_able_to(:destroy, image)

      is_expected.to be_able_to(:read, :local_authorities)
      is_expected.to be_able_to(:destroy, :local_authorities)

      is_expected.to be_able_to(:new_merge, local_group)
      is_expected.to be_able_to(:merge, local_group)
      is_expected.to be_able_to(:merge, SolrDocument.new(local_group.to_solr))

      is_expected.not_to be_able_to(:discover, Hydra::AccessControls::Embargo)
      is_expected.not_to be_able_to(:edit_rights, ActiveFedora::Base)
    }
  end

  context 'for a rights admin user' do
    let(:user) { create(:rights_admin) }

    it {
      is_expected.to be_able_to(:discover, Hydra::AccessControls::Embargo)
      is_expected.to be_able_to(:update_rights, ActiveFedora::Base)
      is_expected.to be_able_to(:update_rights, String) # Hydra-collections calls this on the id
    }
  end
end
