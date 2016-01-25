require 'rails_helper'

describe UpdateMetadataFromProquestFile do
  describe '#embargo_start_date' do
    let(:etd) { double }
    subject { described_class.new(etd).embargo_start_date }

    before do
      allow_any_instance_of(described_class).to receive(:attributes) { attrs }
    end

    context 'with DISS_agreement_decision_date' do
      let(:attrs) do
        { DISS_agreement_decision_date: '2014-08-13 21:57:25',
          DISS_accept_date: '01/01/2013' }
      end
      let(:date) { Date.parse('2014-08-13') }
      it { is_expected.to eq date }
    end

    context 'with DISS_accept_date that is not Jan 1' do
      let(:attrs) do
        { DISS_accept_date: '06/01/2014',
          DISS_agreement_decision_date: nil }
      end
      it { is_expected.to eq Date.parse('2014-06-01') }
    end

    context 'with DISS_accept_date of Jan 1' do
      let(:attrs) { { DISS_accept_date: '01/01/2018' } }
      let(:transformed_date) { Date.parse('2018-12-31') }
      it { is_expected.to eq transformed_date }
    end
  end # describe "#embargo_start_date"

  describe '#embargo_release_date' do
    let(:etd) { double }
    subject { described_class.new(etd).embargo_release_date }

    before do
      allow_any_instance_of(described_class).to receive(:attributes) { attrs }
    end

    context 'DISS_delayed_release: with date' do
      let(:attrs) do
        { embargo_code: '4',
          DISS_accept_date: '01/01/2015',
          DISS_agreement_decision_date: '2015-03-18 11:06:41',
          DISS_delayed_release: '2015-10-24 00:00:00',
          DISS_access_option: 'Open access',
          embargo_remove_date: '10/24/2015' }
      end
      it { is_expected.to eq(Date.parse('2015-10-24')) }
    end

    context 'DISS_delayed_release: without date' do
      let(:attrs) do
        { embargo_code: '0',
          DISS_accept_date: '01/01/2015',
          DISS_agreement_decision_date: '2015-03-20 18:39:24',
          DISS_delayed_release: nil,
          DISS_access_option: 'Open access',
          embargo_remove_date: nil }
      end
      it { is_expected.to be_nil }
    end

    context 'DISS_delayed_release: 2 years' do
      let(:attrs) do
        { embargo_code: '3',
          DISS_accept_date: '01/01/2014',
          DISS_agreement_decision_date: '2014-06-11 23:12:18',
          DISS_delayed_release: '2 years',
          DISS_access_option: 'Campus use only',
          embargo_remove_date: nil }
      end
      it { is_expected.to eq(Date.parse('2016-06-11')) }
    end

    context 'DISS_delayed_release: 1 year' do
      let(:attrs) do
        { embargo_code: '2',
          DISS_accept_date: '01/01/2014',
          DISS_agreement_decision_date: '2013-12-15 19:40:31',
          DISS_delayed_release: '1 years',
          DISS_access_option: 'Campus use only',
          embargo_remove_date: nil }
      end
      it { is_expected.to eq(Date.parse('2014-12-15')) }
    end

    context 'DISS_delayed_release: 6 months' do
      let(:attrs) do
        { embargo_code: '1',
          DISS_accept_date: '01/01/2014',
          DISS_agreement_decision_date: '2014-08-13 21:57:25',
          DISS_delayed_release: '6 months',
          DISS_access_option: 'Open access',
          embargo_remove_date: nil }
      end
      it { is_expected.to eq(Date.parse('2015-02-13')) }
    end

    context 'embargo_code 0: no embargo' do
      let(:attrs) do
        { embargo_code: '0',
          DISS_accept_date: '01/01/2014',
          DISS_agreement_decision_date: nil,
          DISS_delayed_release: nil,
          DISS_access_option: nil,
          embargo_remove_date: nil }
      end
      it { is_expected.to be_nil }
    end

    context 'embargo_code 1: 6-month embargo' do
      let(:attrs) do
        { embargo_code: '1',
          DISS_accept_date: '01/01/2013',
          DISS_agreement_decision_date: nil,
          DISS_delayed_release: nil,
          DISS_access_option: nil,
          embargo_remove_date: nil }
      end
      it { is_expected.to eq(Date.parse('2014-06-30')) }
    end

    context 'embargo_code 2: 1-year embargo' do
      let(:attrs) do
        { embargo_code: '2',
          DISS_accept_date: '01/01/2014',
          DISS_agreement_decision_date: nil,
          DISS_delayed_release: nil,
          DISS_access_option: nil,
          embargo_remove_date: nil }
      end
      it { is_expected.to eq(Date.parse('2015-12-31')) }
    end

    context 'embargo_code 3: 2-year embargo' do
      let(:attrs) do
        { embargo_code: '3',
          DISS_accept_date: '01/01/2014',
          DISS_agreement_decision_date: nil,
          DISS_delayed_release: nil,
          DISS_access_option: nil,
          embargo_remove_date: nil }
      end
      it { is_expected.to eq(Date.parse('2016-12-31')) }
    end

    context 'embargo_code 4: with specified end date' do
      let(:attrs) do
        { embargo_code: '4',
          DISS_accept_date: '01/01/2013',
          DISS_agreement_decision_date: nil,
          DISS_delayed_release: nil,
          DISS_access_option: 'Campus use only',
          embargo_remove_date: '2017-04-24 00:00:00' }
      end
      it { is_expected.to eq(Date.parse('2017-04-24')) }
    end

    context 'embargo_code 4: with no end date' do
      let(:attrs) do
        { embargo_code: '4',
          DISS_accept_date: '01/01/2013',
          DISS_agreement_decision_date: nil,
          DISS_delayed_release: nil,
          DISS_access_option: nil,
          embargo_remove_date: nil }
      end
      it { is_expected.to be_nil }
    end
  end  # describe "#embargo_release_date"

  describe '#policy_during_embargo' do
    let(:etd) { double }

    subject { described_class.new(etd).policy_during_embargo }
    it { is_expected.to eq(AdminPolicy::DISCOVERY_POLICY_ID) }
  end  # describe "#policy_during_embargo"

  describe '#policy_after_embargo' do
    let(:etd) { double }
    subject { described_class.new(etd).policy_after_embargo }

    before do
      allow_any_instance_of(described_class).to receive(:attributes) { attrs }
    end

    context 'a record that has <DISS_access_option>' do
      context "with 'Open access'" do
        let(:attrs) do
          { embargo_code: '0',
            DISS_accept_date: '01/01/2015',
            DISS_agreement_decision_date: '2015-03-20 18:39:24',
            DISS_delayed_release: nil,
            DISS_access_option: 'Open access',
            embargo_remove_date: nil }
        end
        it { is_expected.to eq(AdminPolicy::PUBLIC_POLICY_ID) }
      end

      context "with 'Campus use only'" do
        let(:attrs) do
          { embargo_code: '3',
            DISS_accept_date: '01/01/2014',
            DISS_agreement_decision_date: '2014-06-11 23:12:18',
            DISS_delayed_release: '2 years',
            DISS_access_option: 'Campus use only',
            embargo_remove_date: nil }
        end
        it { is_expected.to eq(AdminPolicy::PUBLIC_CAMPUS_POLICY_ID) }
      end

      context "with slightly different 'Open access' string" do
        let(:attrs) { { DISS_access_option: 'OPEN aCCess.' } }
        it { is_expected.to eq(AdminPolicy::PUBLIC_POLICY_ID) }
      end

      context "with slightly different 'Campus use' string" do
        let(:attrs) { { DISS_access_option: ' campus Use.' } }
        it { is_expected.to eq(AdminPolicy::PUBLIC_CAMPUS_POLICY_ID) }
      end

      context "with text that doesn't match known policies" do
        let(:attrs) { { DISS_access_option: 'something unknown' } }
        it { is_expected.to eq(AdminPolicy::RESTRICTED_POLICY_ID) }
      end
    end

    context 'a record in batch #3 (does not have <DISS_access_option>)' do
      let(:attrs) do
        { embargo_code: '2',
          DISS_accept_date: '01/01/2014',
          DISS_agreement_decision_date: nil,
          DISS_delayed_release: nil,
          DISS_access_option: nil,
          embargo_remove_date: nil }
      end
      it { is_expected.to eq(AdminPolicy::PUBLIC_CAMPUS_POLICY_ID) }
    end
  end  # describe "#policy_after_embargo"

  describe '#run' do
    let(:reloaded) { ETD.find(etd.id) } # reload the ETD to test persisted state

    let(:etd) do
      obj = create(:etd)
      obj.proquest.original_name = File.basename(file)
      obj.proquest.content = File.new(file)
      obj.proquest.mime_type = 'application/xml'
      obj.save!
      obj.reload
    end
    let(:service) { described_class.new(etd) }
    let(:run) { service.run }

    before do
      AdminPolicy.ensure_admin_policy_exists
      run
      etd.save!
    end

    context "when proquest file contents aren't parseable" do
      let(:run) do
        allow($stdout).to receive(:puts) # Squelch output
        described_class.new(etd).run
      end
      let(:policy_id) { AdminPolicy::PUBLIC_POLICY_ID }
      let(:etd) do
        obj = create(:etd, admin_policy_id: policy_id)
        obj.proquest.original_name = 'my_data_file.xml'
        obj.proquest.content = 'something unparseable'
        obj.proquest.mime_type = 'application/xml'
        obj.save!
        obj.reload
      end

      it "doesn't change policy or embargo data" do
        expect(reloaded.embargo_release_date).to be_nil
        expect(reloaded.visibility_during_embargo).to be_nil
        expect(reloaded.visibility_after_embargo).to be_nil
        expect(reloaded.admin_policy_id).to eq policy_id
        expect(reloaded.under_embargo?).to eq false
      end
    end

    context 'for a normal import with no errors' do
      let(:file)  { "#{fixture_path}/proquest/Johnson_ucsb_0035N_12164_DATA.xml" }

      it 'imports metadata from proquest file' do
        expect(reloaded.embargo_release_date).to eq(Date.parse('2014-06-11') + 2.years)
        expect(reloaded.visibility_during_embargo.id).to eq ActiveFedora::Base.id_to_uri(AdminPolicy::DISCOVERY_POLICY_ID)
        expect(reloaded.visibility_after_embargo.id).to eq ActiveFedora::Base.id_to_uri(AdminPolicy::PUBLIC_CAMPUS_POLICY_ID)
        expect(reloaded.admin_policy_id).to eq AdminPolicy::DISCOVERY_POLICY_ID
        expect(reloaded.under_embargo?).to eq true
      end
    end

    context 'with embargo code 4 and an end date' do
      let(:file)  { "#{fixture_path}/proquest/Shockey_ucsb_0035D_11990_DATA.xml" }

      it 'imports metadata from proquest file' do
        expect(reloaded.embargo_release_date).to eq(Date.parse('2017-04-24'))
        expect(reloaded.admin_policy_id).to eq AdminPolicy::DISCOVERY_POLICY_ID
        expect(reloaded.visibility_during_embargo.id).to eq ActiveFedora::Base.id_to_uri(AdminPolicy::DISCOVERY_POLICY_ID)
        expect(reloaded.visibility_after_embargo.id).to eq ActiveFedora::Base.id_to_uri(AdminPolicy::PUBLIC_CAMPUS_POLICY_ID)
        expect(reloaded.under_embargo?).to eq true
      end
    end

    context 'when the embargo is in the past and descripive metadata are present' do
      let(:file)  { "#{fixture_path}/proquest/MartinezRodriguez_ucsb_0035D_12446_DATA.xml" }

      it 'imports metadata from proquest file' do
        # Even though the embargo is expired, we still apply
        # the embargo so that an admin user will have a chance
        # to review it before lifting the embargo.
        expect(reloaded.embargo_release_date).to eq Date.parse('2014-12-15')
        expect(reloaded.visibility_during_embargo.id).to eq ActiveFedora::Base.id_to_uri(AdminPolicy::DISCOVERY_POLICY_ID)
        expect(reloaded.visibility_after_embargo.id).to eq ActiveFedora::Base.id_to_uri(AdminPolicy::PUBLIC_CAMPUS_POLICY_ID)
        expect(reloaded.admin_policy_id).to eq AdminPolicy::DISCOVERY_POLICY_ID
        expect(reloaded.date_copyrighted).to eq [2014]
        expect(reloaded.rights_holder).to eq ['Nadine Martinez Rodriguez']
      end
    end

    context 'when there is no embargo release date' do
      context 'with embargo_code = 4' do
        let(:file)  { "#{fixture_path}/proquest/French_ucsb_0035D_11752_DATA.xml" }

        it 'sets an "infinite embargo"' do
          # It's not really an embargo; it's a permanent state
          # (because we don't expect the access policy to
          # change in the future), so we just need to make
          # sure the access policy is correct.
          expect(reloaded.embargo_release_date).to be_nil
          expect(reloaded.visibility_during_embargo).to be_nil
          expect(reloaded.visibility_after_embargo).to be_nil
          expect(reloaded.under_embargo?).to eq false
          expect(reloaded.admin_policy_id).to eq AdminPolicy::DISCOVERY_POLICY_ID
        end
      end

      context 'with <DISS_delayed_release> empty: no embargo' do
        let(:file)  { "#{fixture_path}/proquest/Flowers_ucsb_0035D_12540_DATA.xml" }

        it 'sets the access policy, no embargo' do
          expect(reloaded.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
          expect(reloaded.under_embargo?).to be_falsey
          expect(reloaded.embargo_release_date).to be_nil
          expect(reloaded.visibility_during_embargo).to be_nil
          expect(reloaded.visibility_after_embargo).to be_nil
        end
      end

      context 'with ProQuest embargo but without ADRL embargo' do
        let(:file)  { "#{fixture_path}/proquest/Hough_ucsb_0035D_12328_DATA.xml" }

        it 'sets the access policy, no embargo' do
          expect(reloaded.admin_policy_id).to eq AdminPolicy::PUBLIC_CAMPUS_POLICY_ID
          expect(reloaded.under_embargo?).to be_falsey
          expect(reloaded.embargo_release_date).to be_nil
          expect(reloaded.visibility_during_embargo).to be_nil
          expect(reloaded.visibility_after_embargo).to be_nil
        end
      end
    end
  end # describe "#run"
end
