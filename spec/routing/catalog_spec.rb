require 'rails_helper'

describe 'routes to CatalogController:' do
  it 'has routes for arks' do
    expect(get: '/lib/ark:/99999/fk41234567')
      .to route_to(controller: 'catalog', action: 'show', prot: 'ark:',
                   shoulder: '99999', id: 'fk41234567')
  end

  context "when the ark is a audio" do
    before do
      allow(AudioRecording).to receive(:exists?).and_return(true)
    end
    it 'has routes for arks' do
      expect(get: '/lib/ark:/99999/fk41234567')
        .to route_to(controller: 'curation_concerns/audio_recordings', prot: 'ark:',
                     shoulder: '99999', action: 'show', id: 'fk41234567')
    end
  end
end
