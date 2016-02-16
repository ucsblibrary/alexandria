require 'rails_helper'

describe OptionsHelper do
  describe '#digital_origin_options' do
    subject { helper.digital_origin_options }
    it { is_expected.to eq ['digitized other analog', 'born digital', 'reformatted digital', 'digitized microfilm'] }
  end

  describe '#description_standard_options' do
    subject { helper.description_standard_options }
    it { is_expected.to eq %w(aacr rda dacs dcrmg fgdc iso19115 local none) }
  end

  describe '#sub_location_options' do
    subject { helper.sub_location_options }
    it { is_expected.to include Qa::Authorities::Local.subauthority_for('sub_location').all.sample[:label] }
  end

  describe '#license_options' do
    subject { helper.license_options }
    it do
      is_expected.to eq('CC-BY' => 'http://creativecommons.org/licenses/by/4.0/',
                        'CC-BY-NC' => 'http://creativecommons.org/licenses/by-nc/4.0/',
                        'CC-BY-NC-ND' => 'http://creativecommons.org/licenses/by-nc-nd/4.0/',
                        'CC-BY-NC-SA' => 'http://creativecommons.org/licenses/by-nc-sa/4.0/',
                        'CC-BY-ND' => 'http://creativecommons.org/licenses/by-nd/4.0/',
                        'CC-BY-SA' => 'http://creativecommons.org/licenses/by-sa/4.0/',
                        'CC0' => 'http://creativecommons.org/publicdomain/zero/1.0/',
                        'Education Use Permitted' => 'http://opaquenamespace.org/ns/rights/educational/',
                        'Free Access - No Re-Use' => 'http://www.europeana.eu/rights/rr-f/',
                        'Orphan Works' => 'http://opaquenamespace.org/ns/rights/orphan-work-us/',
                        'Public Domain' => 'http://creativecommons.org/publicdomain/mark/1.0/',
                        'Rights Reserved - Restricted Access' => 'http://www.europeana.eu/rights/rr-r/',
                        'Unknown' => 'http://www.europeana.eu/rights/unknown/')
    end
  end

  describe '#copyright_status_options' do
    subject { helper.copyright_status_options }
    it do
      is_expected.to eq('public domain' => 'http://id.loc.gov/vocabulary/preservation/copyrightStatus/pub',
                        'copyrighted' => 'http://id.loc.gov/vocabulary/preservation/copyrightStatus/cpr',
                        'unknown' => 'http://id.loc.gov/vocabulary/preservation/copyrightStatus/unk')
    end
  end

  describe '#relators_json' do
    subject { helper.relators_json }
    it { is_expected.to be_html_safe }
    it 'begins with creator and contributor' do
      expect(subject).to start_with "{\"creator\":\"Creator\",\"contributor\":\"Contributor\""
    end
  end
end
