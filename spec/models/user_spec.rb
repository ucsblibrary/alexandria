require 'rails_helper'

describe User do

  describe '#metadata_admin?' do
    let(:admin_user) { build(:metadata_admin) }
    let(:user) { build(:user) }

    it 'knows when a user is a metadata admin' do
      expect(user.metadata_admin?).to be_falsey
      expect(admin_user.metadata_admin?).to be_truthy
    end
  end

  describe '#groups' do
    let(:user) { described_class.new }
    subject { user.groups }
    context 'for a new user' do
      it { is_expected.to be_empty }
    end

    context 'for an exisiting user' do
      let(:user) { described_class.new }
      before do
        allow(user).to receive(:new_record?).and_return(false)
      end

      context "that doesn't have cached groups" do
        before do
          allow(user).to receive(:ldap_groups).and_return(
            ['cn=metadata_admin,ou=groups,dc=dce,dc=com',
             'cn=rights_admin,ou=groups,dc=dce,dc=com'])
        end

        it 'fetches the groups from ldap' do
          # It adds the "ucsb" group
          expect(subject).to eq %w(metadata_admin rights_admin ucsb)
        end
      end

      context 'that has cached groups' do
        before do
          user.group_list = %w(metadata_admin rights_admin)
          user.groups_list_expires_at = 1.day.from_now
        end

        it 'returns the cached groups' do
          expect(user).not_to receive(:ldap_groups)
          expect(subject).to eq %w(metadata_admin rights_admin)
        end
      end

      context 'that has an expired cache' do
        before do
          user.group_list = %w(foo bar)
          user.groups_list_expires_at = 1.day.ago
        end

        it 'fetches the groups from ldap' do
          expect(user).to receive(:ldap_groups).and_return(['cn=metadata_admin,ou=groups,dc=dce,dc=com',
                                                            'cn=rights_admin,ou=groups,dc=dce,dc=com'])
          # It adds the "ucsb" group
          expect(subject).to eq %w(metadata_admin rights_admin ucsb)
        end
      end
    end
  end
end
