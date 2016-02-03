require 'rails_helper'

describe 'catalog/_show_image.html.erb' do
  let(:config) { CatalogController.blacklight_config }

  let(:sub_loc) { 'Basement, level 6' }
  let(:document) do
    SolrDocument.new(
      id: '123',
      accession_number_ssim: 'AN',
      sub_location_ssm: sub_loc)
  end
  let(:blacklight_configuration_context) do
    Blacklight::Configuration::Context.new(controller)
  end

  before do
    allow(view).to receive(:blacklight_config) { config }
    allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
    allow(controller).to receive(:show_type?).and_return(false)
    allow(controller).to receive(:admin_user?).and_return(false)
    render partial: 'catalog/show_image', locals: { document: document }
  end

  it 'displays the correct label for sub_location' do
    expect(rendered).to have_content("#{I18n.t('simple_form.labels.image.sub_location')}: #{sub_loc}")
  end
end
