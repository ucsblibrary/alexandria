require 'rails_helper'

describe 'curation_concerns/audio_recordings/show.html.erb' do
  let(:presenter) { AudioRecordingPresenter.new(solr_document, nil) }
  let(:solr_document) { SolrDocument.new(id: '123',
                                         title_tesim: 'My Audio',
                                         description_tesim: 'Just a cylinder',
                                         restrictions_tesim: ["Don't be evil"],
                                         alternative_tesim: ["my alt title"],
                                         language_label_ssm: ['English'],
                                         issue_number_ssm: ['Edison Gold Moulded Record: 8958'],
                                         has_model_ssim: ['AudioRecording']) }

  before do
    stub_template "curation_concerns/base/_related_files.html.erb" => 'files'
    view.lookup_context.prefixes += ['curation_concerns/base']
    assign(:presenter, presenter)
  end

  it 'draws the page' do
    expect(view).to receive(:provide).with(:page_title, 'My Audio')
    expect(view).to receive(:provide).with(:page_header)
    render
    expect(rendered).to have_content "Edison Gold Moulded Record: 8958"
    expect(rendered).to have_content 'Just a cylinder'
    expect(rendered).to have_content "Don't be evil"
    expect(rendered).to have_content "my alt title"
    expect(rendered).to have_content "English"
  end
end

