# frozen_string_literal: true

require "rails_helper"

describe ApplicationHelper do
  describe "#policy_title" do
    before { AdminPolicy.ensure_admin_policy_exists }

    subject { helper.policy_title(document) }

    let(:document) do
      SolrDocument.new(isGovernedBy_ssim: [AdminPolicy::DISCOVERY_POLICY_ID])
    end

    it { is_expected.to eq "Discovery access only" }
  end

  describe "#linkify" do
    subject { helper.linkify(url_string) }

    context "a HTTP URL" do
      let(:url_string) { "http://alexandria.ucsb.edu" }

      it do
        is_expected.to eq '<a href="http://alexandria.ucsb.edu">'\
                          "http://alexandria.ucsb.edu</a>"
      end
    end

    context "a HTTPS URL" do
      let(:url_string) { "https://alexandria.ucsb.edu" }

      it do
        is_expected.to eq '<a href="https://alexandria.ucsb.edu">'\
                          "https://alexandria.ucsb.edu</a>"
      end
    end

    context "multiple URLs" do
      let(:url_string) do
        "we have cylinders on http://cylinders.library.ucsb.edu "\
        "as well as https://alexandria.ucsb.edu"
      end

      # rubocop:disable Metrics/LineLength
      it do
        is_expected.to eq 'we have cylinders on <a href="http://cylinders.library.ucsb.edu">http://cylinders.library.ucsb.edu</a> as well as <a href="https://alexandria.ucsb.edu">https://alexandria.ucsb.edu</a>'
      end
      # rubocop:enable Metrics/LineLength
    end

    context "an ARK" do
      subject { helper.linkify("ark:/99999/fk4gx4hm1c") }

      it { is_expected.to eq "ark:/99999/fk4gx4hm1c" }
    end
  end

  describe "#rights_icons" do
    context "an In Copyright URI from rightstatements.org" do
      subject do
        helper.rights_icons("http://rightsstatements.org/vocab/InC/1.0/")
      end

      it { is_expected.to eq ["rights-statements/InC.Icon-Only.dark.png"] }
    end

    context "a Not In Copyright URI from rightstatements.org" do
      subject do
        helper.rights_icons("http://rightsstatements.org/vocab/NoC-CR/1.0/")
      end

      it { is_expected.to eq ["rights-statements/NoC.Icon-Only.dark.png"] }
    end

    context "a Not Evaluated URI from rightstatements.org" do
      subject do
        helper.rights_icons("http://rightsstatements.org/vocab/CNE/1.0/")
      end

      it { is_expected.to eq ["rights-statements/Other.Icon-Only.dark.png"] }
    end

    context "a Copyright Undetermined URI from rightstatements.org" do
      subject do
        helper.rights_icons("http://rightsstatements.org/vocab/UND/1.0/")
      end

      it { is_expected.to eq ["rights-statements/Other.Icon-Only.dark.png"] }
    end

    context "a No Known Copyright URI from rightstatements.org" do
      subject do
        helper.rights_icons("http://rightsstatements.org/vocab/NKE/1.0/")
      end

      it { is_expected.to eq ["rights-statements/Other.Icon-Only.dark.png"] }
    end

    context "a URI from creativecommons.org with multiple categories" do
      subject do
        helper.rights_icons("http://creativecommons.org/licenses/by-nc-sa/2.5/")
      end

      it do
        is_expected.to(
          contain_exactly("creative-commons/by.png",
                          "creative-commons/nc.png",
                          "creative-commons/sa.png")
        )
      end
    end

    context "a Public Domain/Zero URI from creativecommons.org" do
      subject do
        helper.rights_icons("http://creativecommons.org/publicdomain/zero/1.0/")
      end

      it { is_expected.to eq ["creative-commons/zero.png"] }
    end
  end
end
