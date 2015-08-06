require 'rails_helper'

describe ContributorIndexer do
  let(:object) { ETD.new }
  let(:indexer) { described_class.new(object) }

  # The DeepIndexer fetches these labels and passes them to the ContributorIndexer
  let(:solr_doc) {
    {
      'creator_label_tesim' => ['American Film Manufacturing Company'],
      'singer_label_tesim' => ['Haggard, Merle'],
      'photographer_label_tesim' => ['Valerie'],
    }
  }

  subject { indexer.generate_solr_document(solr_doc) }

  context "with remote and local creator/contributors" do
    let(:american_film) { RDF::URI.new("http://id.loc.gov/authorities/names/n87914041") }
    let(:creator) { [american_film] }
    let(:singer) { [RDF::URI.new("http://id.loc.gov/authorities/names/n81053687")] }
    let(:person) { Person.create(foaf_name: 'Valerie') }
    let(:photographer) { [RDF::URI.new(person.uri)] }
    let(:object) { Image.new(creator: creator, singer: singer, photographer: photographer) }

    before do
      allow(object.creator.first).to receive(:rdf_label).and_return(["American Film Manufacturing Company"])
      allow(object.singer.first).to receive(:rdf_label).and_return(["Haggard, Merle"])
    end

    it "finds the sortable creator" do
      expect(subject['creator_label_si']).to eq "American Film Manufacturing Company"
    end

    it "creates contributors" do
      expect(subject['contributor_label_tesim']).to eq ["American Film Manufacturing Company", "Valerie", "Haggard, Merle"]
    end
  end
end
