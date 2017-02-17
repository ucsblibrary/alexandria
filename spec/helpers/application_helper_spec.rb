# frozen_string_literal: true
require "rails_helper"

describe ApplicationHelper do
  describe "#policy_title" do
    before { AdminPolicy.ensure_admin_policy_exists }
    let(:document) { SolrDocument.new(isGovernedBy_ssim: [AdminPolicy::DISCOVERY_POLICY_ID]) }
    subject { helper.policy_title(document) }
    it { is_expected.to eq "Discovery access only" }
  end

  describe "#linkify" do
    context "a HTTP URL" do
      subject { helper.linkify("http://alexandria.ucsb.edu") }
      it { is_expected.to eq '<a href="http://alexandria.ucsb.edu">http://alexandria.ucsb.edu</a>' }
    end

    context "a HTTPS URL" do
      subject { helper.linkify("https://alexandria.ucsb.edu") }
      it { is_expected.to eq '<a href="https://alexandria.ucsb.edu">https://alexandria.ucsb.edu</a>' }
    end

    context "an ARK" do
      subject { helper.linkify("ark:/99999/fk4gx4hm1c") }
      it { is_expected.to eq "ark:/99999/fk4gx4hm1c" }
    end
  end

  describe "#rights_icons" do
    context "an In Copyright URI from rightstatements.org" do
      subject { helper.rights_icons("http://rightsstatements.org/vocab/InC/1.0/") }
      it { is_expected.to eq ["rights-statements/InC.Icon-Only.dark.png"] }
    end

    context "a Not In Copyright URI from rightstatements.org" do
      subject { helper.rights_icons("http://rightsstatements.org/vocab/NoC-CR/1.0/") }
      it { is_expected.to eq ["rights-statements/NoC.Icon-Only.dark.png"] }
    end

    context "a Not Evaluated URI from rightstatements.org" do
      subject { helper.rights_icons("http://rightsstatements.org/vocab/CNE/1.0/") }
      it { is_expected.to eq ["rights-statements/Other.Icon-Only.dark.png"] }
    end

    context "a Copyright Undetermined URI from rightstatements.org" do
      subject { helper.rights_icons("http://rightsstatements.org/vocab/UND/1.0/") }
      it { is_expected.to eq ["rights-statements/Other.Icon-Only.dark.png"] }
    end

    context "a No Known Copyright URI from rightstatements.org" do
      subject { helper.rights_icons("http://rightsstatements.org/vocab/NKE/1.0/") }
      it { is_expected.to eq ["rights-statements/Other.Icon-Only.dark.png"] }
    end

    context "a URI from creativecommons.org with multiple categories" do
      subject { helper.rights_icons("http://creativecommons.org/licenses/by-nc-sa/2.5/") }
      it { is_expected.to contain_exactly("creative-commons/by.png", "creative-commons/nc.png", "creative-commons/sa.png") }
    end

    context "a Public Domain/Zero URI from creativecommons.org" do
      subject { helper.rights_icons("http://creativecommons.org/publicdomain/zero/1.0/") }
      it { is_expected.to eq ["creative-commons/zero.png"] }
    end
  end
end
