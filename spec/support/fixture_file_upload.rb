# frozen_string_literal: true

module FixtureFileUpload
  def fixture_file(path)
    File.open(fixture_file_path(path))
  end

  def fixture_file_path(path)
    Rails.root.join "spec", "fixtures", path
  end
end
