module FixtureFileUpload
  def fixture_file(path)
    File.open(fixture_file_path(path))
  end

  def fixture_file_path(path)
    File.join(Rails.root.to_s, 'spec/fixtures', path)
  end
end
