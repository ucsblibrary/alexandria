# frozen_string_literal: true

require "fileutils"

module Proquest
  extend ActiveSupport::Autoload
  autoload :XML
  autoload :Metadata

  # Sample output:
  # Archive:  /opt/download_root/proquest/etdadmin_upload_292976.zip
  #   inflating: /tmp/jcoyne/Murray_ucsb_0035D_12159.pdf
  #   inflating: /tmp/jcoyne/Murray_ucsb_0035D_12159_DATA.xml
  #   inflating: /tmp/jcoyne/SupplementalFile1.pdf
  #   inflating: /tmp/jcoyne/SupplementalFile2.pdf
  #   inflating: /tmp/jcoyne/SupplementalFile3.pdf
  #
  # @param [String] zipfile The path to the .zip file
  # @return [Array]
  def self.extract(zipfile, dest)
    FileUtils.mkdir_p dest unless Dir.exist?(dest)

    # -j: flatten directory structure in `dest'
    # -o: overwrite existing files in `dest'
    system "unzip", "-j", "-o", zipfile, "-d", dest

    # https://github.library.ucsb.edu/ADRL/alexandria/issues/45#issuecomment-101
    {
      xml: Dir["#{dest}/*ucsb_0035*_DATA.xml"].first,
      pdf: Dir["#{dest}/*ucsb_0035*.pdf"].first,
      supplements: Dir["#{dest}/*"].reject do |f|
        File.basename(f).include?("ucsb_0035")
      end,
    }
  end
end
