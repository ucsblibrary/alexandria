# frozen_string_literal: true

require "rails_helper"
require "local_authority"

describe LocalAuthority do
  describe "::local_authority?" do
    subject { LocalAuthority.local_authority?(record) }

    context "for a fedora object" do
      context "that is a local authority" do
        let(:record) { Person.new }
        it { is_expected.to eq true }
      end

      context "that isnt a local authority" do
        let(:record) { Image.new }
        it { is_expected.to eq false }
      end
    end

    context "for a solr document" do
      context "that is a local authority" do
        let(:record) { SolrDocument.new("has_model_ssim" => "Topic") }
        it { is_expected.to eq true }
      end

      context "that isnt a local authority" do
        let(:record) { SolrDocument.new("has_model_ssim" => "Image") }
        it { is_expected.to eq false }
      end
    end
  end

  describe "::local_name_authority?" do
    subject { LocalAuthority.local_name_authority?(record) }

    context "a record that is a local name" do
      let(:record) { SolrDocument.new("has_model_ssim" => "Group") }
      it { is_expected.to eq true }
    end

    context "a record that isnt a local name" do
      let(:record) { SolrDocument.new("has_model_ssim" => "Topic") }
      it { is_expected.to eq false }
    end
  end

  describe "::local_subject_authority?" do
    subject { LocalAuthority.local_subject_authority?(record) }

    context "a record that is a local subject" do
      let(:record) { SolrDocument.new("has_model_ssim" => "Topic") }
      it { is_expected.to eq true }
    end

    context "a record that isnt a local subject" do
      let(:record) { SolrDocument.new("has_model_ssim" => "Agent") }
      it { is_expected.to eq false }
    end
  end

  describe "#find_or_create_rdf_attribute" do
    context "rights_holder" do
      before { Agent.destroy_all }
      let(:regents_uri) { "http://id.loc.gov/authorities/names/n85088322" }
      let(:regents_string) { "Regents of the Univ." }

      let(:attributes) do
        { rights_holder: [RDF::URI.new(regents_uri), regents_string] }
      end

      context "when local rights holder doesn't exist" do
        it "creates a rights holder" do
          expect(Agent.count).to eq 0
          rh = nil
          expect do
            rh = LocalAuthority.find_or_create_rdf_attribute(
              :rights_holder, attributes
            )
          end.to change { Agent.count }.by(1)

          expect(rh.fetch(:rights_holder).map(&:class).uniq).to eq [RDF::URI]
          local_rights_holder = Agent.first
          expect(local_rights_holder.foaf_name).to eq regents_string

          expect(rh.fetch(:rights_holder)).to(
            eq [regents_uri, local_rights_holder.public_uri]
          )
        end
      end

      context "when existing local rights holder" do
        let!(:existing_rh) { Agent.create(foaf_name: regents_string) }

        it "finds the existing rights holder" do
          rh = nil
          expect do
            rh = LocalAuthority.find_or_create_rdf_attribute(
              :rights_holder, attributes
            )
          end.to change { Agent.exact_model.count }.by(0)

          expect(rh.fetch(:rights_holder).map(&:to_s)).to(
            eq [regents_uri, existing_rh.public_uri]
          )
        end
      end

      context "when similar name" do
        let!(:frodo) { Agent.create(foaf_name: "Frodo Baggins") }
        let(:attributes) { { rights_holder: ["Bilbo Baggins"] } }

        it "only finds exact name matches" do
          expect do
            LocalAuthority.find_or_create_rdf_attribute(
              :rights_holder, attributes
            )
          end.to change { Agent.count }.by(1)

          expect(Agent.all.map(&:foaf_name).sort).to(
            eq ["Bilbo Baggins", "Frodo Baggins"]
          )
        end
      end

      context "when name matches, but model is wrong" do
        let!(:frodo) { Person.create(foaf_name: "Frodo Baggins") }
        let(:attributes) { { rights_holder: ["Frodo Baggins"] } }

        it "only matches exact model" do
          expect do
            LocalAuthority.find_or_create_rdf_attribute(
              :rights_holder, attributes
            )
          end.to change { Agent.count }.by(1)
        end
      end

      context "when the type is specified" do
        let(:attributes) do
          { rights_holder: [{ name: "Bilbo Baggins",
                              type: "Person", },], }
        end

        it "creates the local rights holder" do
          rh = nil
          expect do
            rh = LocalAuthority.find_or_create_rdf_attribute(
              :rights_holder, attributes
            )
          end.to change { Person.count }.by(1)
          expect(rh.fetch(:rights_holder).map(&:class)).to eq [RDF::URI]
        end
      end
    end

    context "lc_subject" do
      let(:afmc) { "http://id.loc.gov/authorities/names/n87914041" }
      let(:afmc_uri) { RDF::URI.new(afmc) }

      let(:attributes) do
        {
          lc_subject: [
            { name: "Bilbo Baggins", type: "Person" },
            afmc_uri,
            { name: "A Local Subj", type: "Topic" },
            { name: "Loyal Order of Moose", type: "organization" },
          ],
        }
      end

      context "local authorities don't exist yet" do
        before do
          Person.delete_all
          Topic.delete_all
          Organization.delete_all
        end

        it "creates the missing local subjects" do
          attrs = nil
          expect do
            attrs = LocalAuthority.find_or_create_rdf_attribute(
              :lc_subject, attributes
            )
          end.to(
            change { Person.count }.by(1).and(
              change { Topic.count }.by(1).and(
                change { Organization.count }.by(1)
              )
            )
          )

          bilbo = Person.first
          expect(bilbo.foaf_name).to eq "Bilbo Baggins"

          subj = Topic.first
          expect(subj.label).to eq ["A Local Subj"]

          org = Organization.first
          expect(org.label).to eq ["Loyal Order of Moose"]

          expect(attrs[:lc_subject]).to(
            contain_exactly(bilbo.public_uri,
                            afmc,
                            subj.public_uri,
                            org.public_uri)
          )
        end
      end
    end

    context "location" do
      before { Topic.delete_all }

      let(:attributes) do
        { location: ["Missouri"] }
      end

      context "locations don't exist yet" do
        it "creates a new topic" do
          attrs = nil
          expect do
            attrs = LocalAuthority.find_or_create_rdf_attribute(
              :location, attributes
            )
          end.to change { Topic.count }.by 1

          top = Topic.first
          expect(top.label).to eq ["Missouri"]
          expect(attrs[:location]).to eq [top.public_uri]
        end
      end

      context "locations already exist" do
        let!(:topic) { Topic.create(label: ["Missouri"]) }

        it "finds the existing topic" do
          attrs = nil
          expect do
            attrs = LocalAuthority.find_or_create_rdf_attribute(
              :location, attributes
            )
          end.to change { Topic.count }.by 0

          expect(attrs[:location].map(&:to_s)).to eq [topic.public_uri]
        end
      end
    end
  end # find_or_create_rdf_attribute

  describe "#find_or_create_contributors" do
    let(:afmc) { "http://id.loc.gov/authorities/names/n87914041" }
    let(:afmc_uri) { RDF::URI.new(afmc) }
    let(:fields) { [:creator, :collector, :contributor] }
    let(:joel) { "Joel Conway" }

    before { Agent.destroy_all }

    # The attributes hash that comes from the ModsParser
    let(:attributes) do
      { creator: [afmc_uri],
        contributor: [afmc_uri, { name: joel, type: "personal" }], }
    end

    context "when contributors don't exist yet" do
      it "creates the contributors and returns a hash of the contributors" do
        expect(Person.count).to eq 0
        contributors = nil

        expect do
          contributors = LocalAuthority.find_or_create_contributors(
            fields, attributes
          )
        end.to change { Person.count }.by(1)

        expect(contributors.keys.sort).to eq [:contributor, :creator]
        expect(contributors[:creator].first.class).to eq RDF::URI
        expect(contributors[:creator]).to eq [afmc]
        expect(contributors[:contributor].count).to eq 2
        expect(contributors[:contributor].map(&:class).uniq).to eq [RDF::URI]
        new_person = Person.first
        expect(new_person.foaf_name).to eq joel
        expect(contributors[:contributor]).to include new_person.public_uri
        expect(contributors[:contributor]).to include afmc
      end
    end

    context "when contributors already exist" do
      let!(:person) { Person.create(foaf_name: joel) }

      it "returns a hash of the contributors" do
        contributors = nil
        expect do
          contributors = LocalAuthority.find_or_create_contributors(
            fields, attributes
          )
        end.to change { Person.count }.by(0)

        expect(contributors.keys.sort).to eq [:contributor, :creator]
        expect(contributors[:creator].first.class).to eq RDF::URI
        expect(contributors[:creator]).to eq [afmc]
        expect(contributors[:contributor].count).to eq 2
        expect(contributors[:contributor].map(&:class).uniq).to eq [RDF::URI]
        expect(contributors[:contributor]).to include afmc
        expect(contributors[:contributor]).to include person.public_uri
      end
    end

    context "when similar name" do
      let!(:frodo) { Person.create(foaf_name: "Frodo Baggins") }
      let(:attributes) do
        { creator: [{ name: "Bilbo Baggins", type: "personal" }] }
      end

      it "only finds exact name matches" do
        expect do
          LocalAuthority.find_or_create_contributors([:creator], attributes)
        end.to change { Person.count }.by(1)

        expect(Person.all.map(&:foaf_name).sort).to(
          eq ["Bilbo Baggins", "Frodo Baggins"]
        )
      end
    end

    context "with class directly given in the type field" do
      # The attributes hash that comes from the CSVParser
      let(:attributes) do
        { creator: [{ name: "Bilbo Baggins", type: "Person" }],
          composer: [{ name: "Frodo", type: "Group" }], }
      end
      let(:fields) { [:creator, :composer] }

      it "creates the local authorities" do
        expect do
          LocalAuthority.find_or_create_contributors(fields, attributes)
        end.to change { Person.count }.by(1)
          .and change { Group.count }.by(1)
      end
    end
  end # '#find_or_create_contributors'
end
