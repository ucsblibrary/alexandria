require 'rails_helper'

describe GenericFile do
  describe '.indexer' do
    subject { described_class.indexer }
    it { is_expected.to eq GenericFileIndexer }
  end
end
