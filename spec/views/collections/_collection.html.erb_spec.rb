require 'rails_helper'

describe 'collections/_collection.html.erb' do
  let(:config) { CatalogController.blacklight_config }

  before do
    allow(view).to receive(:blacklight_config) { config }
    allow(view).to receive(:collection_counter) { 0 }
  end

  context 'with a long description' do
    let(:beginning) { 'Some description text ' }
    let(:ending) { 'the last words of the description' }
    let(:long_desc) do
      desc = beginning
      8.times { desc += desc }
      desc + ending
    end
    let(:collection) do
      SolrDocument.new(id: '123',
                       'title_tesim' => 'My Collection',
                       'description_tesim' => [long_desc])
    end
    let(:blacklight_configuration_context) do
      Blacklight::Configuration::Context.new(controller)
    end

    before do
      stub_template '_index_header_default.html.erb' => '',
                    '_index_default.html.erb' => ''
      allow(view).to receive(:collection) { collection }
      allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
      render
    end

    it 'displays truncated description' do
      # The HTML should have divs with these classes.
      # They are needed by the javascript.
      expect(rendered).to have_css '.show-more'
      expect(rendered).to have_css '.show-less'
      expect(rendered).to have_css '.reveal-js'

      # The description should be truncated in this div
      within('.show-more') do
        expect(page).to have_content beginning
        expect(page).to_not have_content ending
      end

      # The description shouldn't be truncated here
      within('.show-less') do
        expect(page).to have_content beginning
        expect(page).to have_content ending
      end
    end
  end
end
