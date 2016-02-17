module ExtractFulltextLink
  # Filters out 856u fields that look like: http://alexandria.ucsb.edu/lib/ark:/48907/f3gt5k61
  # We're attempting to capture URLs that look like:
  #   http://gateway.proquest.com/openurl?url_ver=Z39.88-2004&amp;rft_val_fmt=info:ofi/fmt:kev:mtx:dissertation&amp;res_dat=xri:pqm&amp;rft_dat=xri:pqdiss:3602190
  #   OR
  #   http://www.library.ucsb.edu/OBJID/Cylinder4374
  def extract_fulltext_link
    extract856u = Traject::MarcExtractor.new('856u', separator: nil)
    lambda do |record, accumulator|
      extract856u.extract(record).grep_v(%r{^http://alexandria\.ucsb\.edu/lib/}).each do |val|
        accumulator << val
      end
    end
  end
end
