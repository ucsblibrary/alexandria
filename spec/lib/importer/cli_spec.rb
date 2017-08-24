# coding: utf-8
# frozen_string_literal: true

require "rails_helper"
require "importer"

describe Importer::CLI do
  describe "::find_paths" do
    context "with a file in subdirectories" do
      subject { described_class.find_paths([tmpdir]) }

      let(:tmpdir) { Pathname.new(Dir.mktmpdir) }

      it "finds the nested file" do
        FileUtils.mkdir_p tmpdir.join("nested", "directories")
        FileUtils.touch tmpdir.join("nested", "directories", "with_a_file")

        expect(subject).to(
          contain_exactly(
            tmpdir.join("nested", "directories", "with_a_file").to_s
          )
        )
      end
    end

    context "with no files" do
      subject { described_class.find_paths([tmpdir]) }

      let(:tmpdir) { Pathname.new(Dir.mktmpdir) }

      it "finds nothing" do
        FileUtils.mkdir_p tmpdir.join("nested", "directories")

        expect(subject).to be_empty
      end
    end
  end
end
