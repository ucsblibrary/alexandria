# frozen_string_literal: true

# ensure these directories exist
[
  Settings.download_root,
  Settings.marc_directory,
  Settings.proquest_directory,
].each do |dir|
  FileUtils.mkdir_p dir unless Pathname.new(dir).exist?
end
