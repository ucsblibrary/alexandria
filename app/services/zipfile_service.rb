# Proquest ships us a directory of zipfiles that contain a PDF, an XML
# file with rights/embargo data and possibly some supplementary
# files. The only way to associate the zip file with the MARC record
# for the ETD is that the MARC record has the name of the pdf file
# contained within one of the zipfiles.  This service identifies the
# zipfile based on the pdf name and extracts all the files so we can
# save them with the Fedora object.
class ZipfileService
  attr_reader :pdf_file_name
  # @param [String] pdf_file_name the base name of the PDF file to find
  def initialize(pdf_file_name)
    @pdf_file_name = pdf_file_name
  end

  # @param [String] dir the directory to extract the files to
  # @return [ExtractedFiles] paths to the extracted files
  def extract_files(dir)
    zip_path = find_zip_file
    return unless zip_path

    filenames = extracted_files(run_unzip(zip_path, dir))
    filenames.each_with_object(ExtractedFiles.new) do |filename, extracted|
      if File.basename(filename) == pdf_file_name
        extracted.pdf = filename
      elsif File.basename(filename) == "#{File.basename(pdf_file_name, '.pdf')}_DATA.xml"
        extracted.proquest = filename
      else
        extracted.add_supplemental filename
      end
    end
  end

  class ExtractedFiles < Struct.new(:pdf, :proquest, :supplemental)
    def initialize(pdf = nil, proquest = nil, supplemental = [])
      self.pdf = pdf
      self.proquest = proquest
      self.supplemental = supplemental
    end

    def add_supplemental(val)
      self.supplemental ||= []
      supplemental << val
    end
  end

  private

    def extracted_files(raw_output)
      raw_output.split("\n").grep(/inflating/).map do |line|
        line.gsub(/\s*inflating: /, '').rstrip
      end
    end

    # @return [String, NilClass] the path tf the zipfile containing the pdf file
    def find_zip_file
      ActiveSupport::Notifications.instrument('find_zip.importer',
                                              id: pdf_file_name, name: 'Search for zipfile') do
        results = `for f in #{wildcard_zip}; do unzip -l $f | grep -q #{pdf_file_name} && echo $f; done`
        results.chomp!
        results.empty? ? nil : results
      end
    end

    # Returns the output from extracting the archive to the tempdir
    #
    # Sample output:
    # Archive:  /opt/download_root/proquest/etdadmin_upload_292976.zip
    #   inflating: /tmp/jcoyne/Murray_ucsb_0035D_12159.pdf
    #   inflating: /tmp/jcoyne/Murray_ucsb_0035D_12159_DATA.xml
    #   inflating: /tmp/jcoyne/SupplementalFile1.pdf
    #   inflating: /tmp/jcoyne/SupplementalFile2.pdf
    #   inflating: /tmp/jcoyne/SupplementalFile3.pdf
    def run_unzip(zip_path, dir)
      `unzip -j "#{zip_path}" -d "#{dir}"`
    end

    # @return [String] a pattern for seaching the zip files.
    def wildcard_zip
      File.join(Shellwords.escape(Settings.proquest_directory), '*.zip')
    end
end
