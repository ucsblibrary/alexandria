require 'rails_helper'

describe ETDIndexer do
  subject { described_class.new(etd).generate_solr_document }

  context "with a generic_file" do
    let(:generic_file) { GenericFile.new(id: 'bf/74/27/75/bf742775-2a24-46dc-889e-cca03b27b5f3') }
    let(:etd) { ETD.new(generic_files: [generic_file]) }

    it "has downloads" do
      expect(subject['generic_file_ids_ssim']).to eq ['bf/74/27/75/bf742775-2a24-46dc-889e-cca03b27b5f3']
    end
  end

end

