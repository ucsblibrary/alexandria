require 'spec_helper'

describe Oargun::RDF::Controlled do
  before do
    class DummyResource < ActiveTriples::Resource
      include Oargun::RDF::Controlled
    end
  end

  describe "repository" do
    subject { DummyResource.repository }
    it { is_expected.to eq :vocabs }
  end
end
